-- Run: tests/run.sh tests/projectionist_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local child = dofile(tests_dir .. '/support/editor.lua')

local project = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(project, 'p')
vim.fn.writefile({}, project .. '/Gemfile')
vim.fn.writefile({}, project .. '/Gemfile.lock')
local editor, job = child.start({ cwd = project, files = { 'Gemfile' } })
vim.rpcrequest(editor, 'nvim_input', '<F3>')
local current
vim.wait(3000, function()
  current = vim.rpcrequest(editor, 'nvim_exec_lua', "return vim.fn.expand('%:t')", {})
  return current == 'Gemfile.lock'
end)
vim.fn.jobstop(job)
equals('F3 opens the alternate of the first buffer of a new editor', current, 'Gemfile.lock')

report.finish()
