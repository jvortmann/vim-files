-- Run: tests/run.sh tests/ts-autotag_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local lines_after_keys = dofile(tests_dir .. '/support/typing.lua').lines_after_keys

-- After nvim_feedkeys, the next message starts without a newline. So feed all keys first, and report the checks after.
local closed_erb = lines_after_keys('.html.erb', { '' }, 'i<div>x')

equals('typing an open tag in html.erb adds its closing tag, with the cursor between them', closed_erb, { '<div>x</div>' })

report.finish()
