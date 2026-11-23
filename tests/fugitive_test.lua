-- Run: tests/run.sh tests/fugitive_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local git_at_startup = vim.fn.exists(':Git')

equals('fugitive is loaded at startup, before any key', git_at_startup, 2)

report.finish()
