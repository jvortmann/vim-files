#!/usr/bin/env bash
# Runs one test file in headless Neovim with the config of ~/.config/nvim, and prints its TAP on stdout. run.sh runs it.
# A file that runs longer than TEST_TIMEOUT seconds (120 by default) ends with a not ok line.
test_timeout="${TEST_TIMEOUT:-120}"
started=$SECONDS

# The config sets clipboard to unnamed, so a yank or a delete runs pbcopy. A fake pbcopy and pbpaste first on PATH keep
# the test off the clipboard of the user. They keep the copied text in the file TEST_CLIPBOARD. Each nvim that the test
# starts, also in tmux, gets the same PATH.
fake_bin="$(mktemp -d)" || exit 1
trap 'rm -r "$fake_bin"' EXIT
export TEST_CLIPBOARD="$fake_bin/clipboard"
printf '#!/bin/sh\ncat >"%s"\n' "$TEST_CLIPBOARD" >"$fake_bin/pbcopy"
printf '#!/bin/sh\ncat "%s" 2>/dev/null\nexit 0\n' "$TEST_CLIPBOARD" >"$fake_bin/pbpaste"
chmod +x "$fake_bin/pbcopy" "$fake_bin/pbpaste"
export PATH="$fake_bin:$PATH"
# A file that throws a Lua error never reaches report.finish, so it prints no plan. The cquit then makes nvim exit with status 1.
# A stuck nvim can ignore SIGTERM, so -k sends SIGKILL 5 seconds later.
timeout -k 5 "$test_timeout" nvim -i NONE --headless -c "luafile $1" -c cquit </dev/null
code=$?
# timeout exits with 124 after SIGTERM, and with 137 after SIGKILL. Another SIGKILL also gives 137, so the time must have run out too.
if [ "$code" -eq 124 ] || { [ "$code" -eq 137 ] && [ "$((SECONDS - started))" -ge "$test_timeout" ]; }; then
  printf 'not ok - %s timed out after %s s\n' "$1" "$test_timeout"
fi
exit "$code"
