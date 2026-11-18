-- Run: nvim --headless -c 'luafile tests/gist_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

equals('a new gist is private', vim.g.gist_post_private, 1)
equals('the gist list shows private gists', vim.g.gist_show_privates, 1)

report.finish()
