-- Run: tests/run.sh tests/projectionist_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')
local check = report.check
local equals = report.equals
local child = dofile(tests_dir .. '/support/editor.lua')

local _, nontest = pcall(vim.api.nvim_eval, "map(['a/b.test', 'a/b.spec', 'a/b'], "
  .. "'g:projectionist_transformations.nontest(v:val, {})')")
equals(
  'the nontest transformation of projectionist drops test and spec names',
  nontest,
  { '\24', '\24', 'a/b' }
)

local expected_heuristics = vim.fn.readfile(tests_dir .. '/fixtures/projectionist_heuristics.txt')[1]
local heuristics = vim.api.nvim_eval('string(g:projectionist_heuristics)')
check(
  'projectionist gets the heuristics of the VimScript settings, in the same key order',
  heuristics == expected_heuristics,
  'got ' .. heuristics
)

local undescribed = keymaps.undescribed({ '<F3>', '<S-F3>', '<leader>t', '<leader>t<space>', '<leader>ts', '<leader>tv' })
equals('every projectionist map has a description for which-key', undescribed, {})

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
