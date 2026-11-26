# Tests

The tests are `tests/*_test.lua`, and `tests/run.sh` runs them. The first line
of each test file gives the command for that file. The section "Tests" of
`README.md` describes the output. The full suite takes about 4 seconds.

```sh
TEST_TIMEOUT=20 timeout -k 5 30 tests/run.sh </dev/null
TEST_TIMEOUT=20 timeout -k 5 30 tests/run.sh tests/grep_test.lua </dev/null
```

`TEST_TIMEOUT` stops one file and names it, so keep it below the outer limit.

`tests/tap-nvim.sh` runs each file as `nvim -i NONE --headless`, with
`</dev/null` and `timeout -k 5`. Give each nvim that you start outside the
suite the same flags and a time limit:

- `-i NONE` keeps the ShaDa folder of the user. The suite fails when it
  changes.
- `</dev/null` stops a prompt, which makes a headless nvim wait forever.
- `timeout -k 5` sends KILL 5 seconds after TERM, because a stuck nvim can
  ignore TERM.

# The clipboard

The config sets `clipboard` to `unnamed`, so each yank and each delete runs
`pbcopy`. A test never touches the clipboard of the user. `tests/tap-nvim.sh`
puts a fake `pbcopy` and `pbpaste` first on `PATH` for each nvim of a test. An
nvim outside the suite has no fake. So put a check that yanks or deletes text in
a test file, and run it with `tests/run.sh`.

# Plugins

lazy.nvim keeps the source of each plugin in `~/.local/share/nvim/lazy/<name>`.
The tree-sitter parsers and queries are in `~/.local/share/nvim/site/parser`
and `~/.local/share/nvim/site/queries`. Mason is in
`~/.local/share/nvim/mason`. These folders belong to the user. A test that
needs to change them uses a temporary `XDG_DATA_HOME`.

`~/.config/nvim` is a link to this repository, so an edit here reaches each
nvim of the user at its next start.

# Files

`fixendofline` is off, and some files have no final newline. Keep the end of
each file as it is: do not add or remove a final newline.

Git ignores `plans/`, so an edit to a plan needs no commit.
