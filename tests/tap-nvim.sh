#!/usr/bin/env bash
# Runs one test file in headless Neovim with the config of ~/.config/nvim, and prints its TAP on stdout. run.sh runs it.
# A file that runs longer than TEST_TIMEOUT seconds (120 by default) ends with a not ok line.
test_timeout="${TEST_TIMEOUT:-120}"
started=$SECONDS

# The config sets clipboard to unnamed, so a yank or a delete runs pbcopy. A fake pbcopy and pbpaste first on PATH keep
# the test off the clipboard of the user. They keep the copied text in the file clipboard in their folder, and
# TEST_CLIPBOARD names that file. Each nvim that the test starts, also in tmux, gets the same PATH.
# The fakes are links to the scripts in tests/support/bin. On macOS, the first run of a new script waits for a security
# scan, and many new scripts at once wait in a queue. A link to a script that ran before starts at once.
support_bin="$(cd "$(dirname "$0")/support/bin" && pwd)" || exit 1
fake_bin="$(mktemp -d)" || exit 1
trap 'rm -r "$fake_bin"' EXIT
export TEST_CLIPBOARD="$fake_bin/clipboard"
ln -s "$support_bin/pbcopy" "$support_bin/pbpaste" "$fake_bin/" || exit 1
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
