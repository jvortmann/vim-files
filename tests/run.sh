#!/usr/bin/env bash
# Runs test files with prove, each in headless Neovim with the config that ~/.config/nvim loads. It runs the files that it
# gets, or every tests/*_test.lua. JOBS sets how many files run at once (the CPU count by default), and TEST_TIMEOUT the
# time limit of one file in seconds (120 by default).
# Exits with status 1 when a file fails, or when the suite changes the ShaDa folder.
set -u
shopt -s nullglob

command -v timeout >/dev/null || { echo 'run.sh needs the timeout command of GNU coreutils' >&2; exit 1; }
command -v prove >/dev/null || { echo 'run.sh needs prove, which comes with Perl' >&2; exit 1; }

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
status=0

# The suite must leave the same file names in the ShaDa folder of the user. An open Neovim of the user can write main.shada during a run, so the check ignores changes to that file.
shada_dir="$(nvim --clean --headless -i NONE -c 'lua io.stdout:write(vim.fn.stdpath("state") .. "/shada")' -c qall </dev/null)"
[ -n "$shada_dir" ] || { echo 'Could not find the ShaDa folder' >&2; exit 1; }
shada_before="$(ls -A "$shada_dir" 2>/dev/null)"

prove -j"${JOBS:-$(getconf _NPROCESSORS_ONLN)}" --timer -e tests/tap-nvim.sh "${test_files[@]}" || status=1

shada_after="$(ls -A "$shada_dir" 2>/dev/null)"
if [ "$shada_after" = "$shada_before" ]; then
  printf 'PASS the suite leaves %s unchanged\n' "$shada_dir"
else
  status=1
  printf 'FAIL the suite changed %s\n' "$shada_dir"
  diff <(printf '%s\n' "$shada_before") <(printf '%s\n' "$shada_after")
fi

exit "$status"
