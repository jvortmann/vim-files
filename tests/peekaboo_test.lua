-- Run: nvim -i NONE --headless -c 'luafile tests/peekaboo_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

equals('peekaboo opens a 65 column window on the right', vim.g.peekaboo_window, 'vert bo 65new')

report.finish()
