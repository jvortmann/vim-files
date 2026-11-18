-- Run: nvim --headless -c 'luafile tests/tools_settings_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local equals = report.equals

if vim.fn.executable('rg') == 1 then
  equals('Ack searches with rg', vim.g.ackprg, "rg --hidden --vimgrep -g '!.git' -g '!/vendor'")
end
local ack_mappings = vim.g.ack_mappings or {}
equals(
  'Ack turns off the h mapping and keeps its own s and v splits',
  { ack_mappings.h, ack_mappings.s, ack_mappings.v },
  { '', '<C-W><CR><C-W>K', '<C-W><CR><C-W>H<C-W>b<C-W>J<C-W>t' }
)
equals('Ack highlights the search term', vim.g.ackhighlight, 1)

equals('a new gist is private', vim.g.gist_post_private, 1)
equals('the gist list shows private gists', vim.g.gist_show_privates, 1)

equals('peekaboo opens a 65 column window on the right', vim.g.peekaboo_window, 'vert bo 65new')

equals(
  'vim-prettier gets its settings before a filetype loads it',
  {
    vim.g['prettier#autoformat_config_present'],
    vim.g['prettier#autoformat_require_pragma'],
    vim.g['prettier#exec_cmd_async'],
    vim.g['prettier#quickfix_enabled'],
  },
  { 1, 0, 1, 0 }
)

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
