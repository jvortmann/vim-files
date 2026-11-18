-- Run: nvim --headless -c 'luafile tests/projectionist_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local equals = report.equals

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

report.finish()
