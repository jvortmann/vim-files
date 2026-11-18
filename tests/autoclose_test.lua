-- Run: nvim --headless -c 'luafile tests/autoclose_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

equals('the autoclose setting keeps its misspelled name and the value 0', vim.g.AutoClosePreservDotReg, 0)

report.finish()
