#!/usr/bin/env bash
# Runs each tests/*_test.lua in headless Neovim, with the config that ~/.config/nvim loads.
# Exits with status 1 when a test file fails or throws.
set -u
shopt -s nullglob

cd "$(dirname "$0")/.." || exit 1
test_files=(tests/*_test.lua)
if [ "${#test_files[@]}" -eq 0 ]; then
  echo 'No tests/*_test.lua files found' >&2
  exit 1
fi
status=0

# The suite must leave the same file names in the ShaDa folder of the user. An open Neovim of the user can write main.shada during a run, so the check ignores changes to that file.
shada_dir="$(nvim --clean --headless -i NONE -c 'lua io.stdout:write(vim.fn.stdpath("state") .. "/shada")' -c qall </dev/null)"
[ -n "$shada_dir" ] || { echo 'Could not find the ShaDa folder' >&2; exit 1; }
shada_before="$(ls -A "$shada_dir" 2>/dev/null)"

for name in "${test_files[@]}"; do
  started=$SECONDS
  # A file that throws a Lua error never reaches report.finish. The cquit then makes nvim exit with status 1.
  if output="$(nvim -i NONE --headless -c "luafile $name" -c cquit </dev/null 2>&1)"; then
    result=PASS
  else
    result=FAIL
    status=1
    printf '%s\n' "$output"
  fi
  checks="$(printf '%s\n' "$output" | grep -c '^ok ')"
  printf '%s %s (%s ok, %ss)\n' "$result" "$name" "$checks" "$((SECONDS - started))"
done

shada_after="$(ls -A "$shada_dir" 2>/dev/null)"
if [ "$shada_after" = "$shada_before" ]; then
  printf 'PASS the suite leaves %s unchanged\n' "$shada_dir"
else
  status=1
  printf 'FAIL the suite changed %s\n' "$shada_dir"
  diff <(printf '%s\n' "$shada_before") <(printf '%s\n' "$shada_after")
fi

exit "$status"
