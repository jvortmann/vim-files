#!/usr/bin/env bash
# Runs test files, each in headless Neovim with the config that ~/.config/nvim loads, and prints one TAP version 14
# stream. It runs the files that it gets, or every tests/*_test.lua. JOBS sets how many files run at once (the CPU count
# by default), and TEST_TIMEOUT the time limit of one file in seconds (120 by default).
# Each file is a subtest, in the order of the files. The ShaDa check is the last test point.
# Exits with status 1 when a file fails, or when the suite changes the ShaDa folder.
set -u
shopt -s nullglob

command -v timeout >/dev/null || { echo 'run.sh needs the timeout command of GNU coreutils' >&2; exit 1; }
[ -n "${EPOCHREALTIME:-}" ] || { echo 'run.sh needs bash 5 or later' >&2; exit 1; }

# The files that the caller gives are relative to its folder, so make them absolute before the cd to the root of the repo.
test_files=()
for name in "$@"; do
  [[ "$name" = /* ]] || name="$PWD/$name"
  test_files+=("$name")
done
cd "$(dirname "$0")/.." || exit 1
[ "${#test_files[@]}" -gt 0 ] || test_files=(tests/*_test.lua)
if [ "${#test_files[@]}" -eq 0 ]; then
  echo 'No tests/*_test.lua files found' >&2
  exit 1
fi

# The suite must leave the same file names in the ShaDa folder of the user. An open Neovim of the user can write main.shada during a run, so the check ignores changes to that file.
shada_dir="$(nvim --clean --headless -i NONE -c 'lua io.stdout:write(vim.fn.stdpath("state") .. "/shada")' -c qall </dev/null)"
[ -n "$shada_dir" ] || { echo 'Could not find the ShaDa folder' >&2; exit 1; }
shada_before="$(ls -A "$shada_dir" 2>/dev/null)"

work="$(mktemp -d)"
trap 'rm -r "$work"' EXIT
run_started=$EPOCHREALTIME

# Runs the test file $2 as number $1, and keeps its stdout and stderr in the work folder. The file $1.done holds the
# exit status and the time in milliseconds. It appears last, so the other two files are complete when it exists.
run_one() {
  local started=$EPOCHREALTIME code
  tests/tap-nvim.sh "$2" >"$work/$1.out" 2>"$work/$1.err"
  code=$?
  printf '%s %s\n' "$code" "$(milliseconds_since "$started")" >"$work/$1.tmp"
  mv "$work/$1.tmp" "$work/$1.done"
}
milliseconds_since() {
  local now=$EPOCHREALTIME
  echo $(( (${now//[^0-9]/} - ${1//[^0-9]/}) / 1000 ))
}
export -f run_one milliseconds_since
export work

for i in "${!test_files[@]}"; do
  printf '%s\0%s\0' "$i" "${test_files[$i]}"
done | xargs -0 -n 2 -P "${JOBS:-$(getconf _NPROCESSORS_ONLN)}" bash -c 'run_one "$@"' _ &
runner=$!

# Color goes to a terminal only, and NO_COLOR turns it off. COLOR=always or COLOR=never overrides both.
case "${COLOR:-auto}" in
  always) color=1 ;;
  never) color=0 ;;
  *) if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then color=1; else color=0; fi ;;
esac
in_yaml=0

# Prints the line $1. With color, an ok line is green, a not ok line red, a Subtest line and the pass line bold, and a
# YAML block or another comment dim.
emit() {
  local start=''
  if [ "$color" -eq 1 ]; then
    if [[ $1 =~ ^\ *---$ ]]; then
      in_yaml=1
      start=$'\e[2m'
    elif [[ $1 =~ ^\ *\.\.\.$ ]]; then
      in_yaml=0
      start=$'\e[2m'
    elif [ "$in_yaml" -eq 1 ]; then
      start=$'\e[2m'
    elif [[ $1 =~ ^\ *ok\  ]]; then
      start=$'\e[32m'
    elif [[ $1 =~ ^\ *not\ ok ]]; then
      start=$'\e[31m'
    elif [[ $1 =~ ^#\ (Subtest:|pass\ ) ]]; then
      start=$'\e[1m'
    elif [[ $1 =~ ^\ *# ]]; then
      start=$'\e[2m'
    fi
  fi
  if [ -n "$start" ]; then
    printf '%s%s\e[0m\n' "$start" "$1"
  else
    printf '%s\n' "$1"
  fi
}

emit 'TAP version 14'
number=0
failed=0
for i in "${!test_files[@]}"; do
  until [ -e "$work/$i.done" ]; do
    # When xargs ended and the file has no result, the file never ran to its end.
    if ! kill -0 "$runner" 2>/dev/null && [ ! -e "$work/$i.done" ]; then
      : >>"$work/$i.out"
      echo 'run.sh got no result for this file' >>"$work/$i.err"
      echo '1 0' >"$work/$i.done"
    fi
    sleep 0.05
  done
  read -r code time <"$work/$i.done"
  name="${test_files[$i]#"$PWD/"}"
  number=$((number + 1))
  emit "# Subtest: $name"
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && emit "    $line"
  done <"$work/$i.out"
  # A file passes when it exits with status 0, prints its plan and prints no not ok line.
  if [ "$code" -eq 0 ] && grep -q '^1\.\.[0-9]' "$work/$i.out" && ! grep -q '^not ok' "$work/$i.out"; then
    emit "ok $number - $name # time=${time}ms"
  else
    failed=$((failed + 1))
    # The stderr of a failed file holds the cause, such as a Lua error. Comment lines keep the stream TAP.
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line//$'\r'/}"
      [ -n "$line" ] && emit "    # $line"
    done <"$work/$i.err"
    emit "not ok $number - $name # time=${time}ms"
  fi
done
wait

number=$((number + 1))
shada_after="$(ls -A "$shada_dir" 2>/dev/null)"
if [ "$shada_after" = "$shada_before" ]; then
  emit "ok $number - the suite leaves $shada_dir unchanged"
else
  failed=$((failed + 1))
  emit "not ok $number - the suite changes $shada_dir"
  emit '  ---'
  emit '  message: |'
  while IFS= read -r line; do
    emit "    $line"
  done < <(diff <(printf '%s\n' "$shada_before") <(printf '%s\n' "$shada_after"))
  emit '  ...'
fi
emit "1..$number"
emit "# pass $((number - failed)), fail $failed"
emit "# wall time $(milliseconds_since "$run_started")ms"

[ "$failed" -eq 0 ]
