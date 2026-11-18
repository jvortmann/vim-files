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

for name in "${test_files[@]}"; do
  started=$SECONDS
  # A file that throws a Lua error never reaches report.finish. The cquit then makes nvim exit with status 1.
  if output="$(nvim --headless -c "luafile $name" -c cquit </dev/null 2>&1)"; then
    result=PASS
  else
    result=FAIL
    status=1
    printf '%s\n' "$output"
  fi
  checks="$(printf '%s\n' "$output" | grep -c '^ok ')"
  printf '%s %s (%s ok, %ss)\n' "$result" "$name" "$checks" "$((SECONDS - started))"
done

exit "$status"
