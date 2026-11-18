-- Run: nvim --headless -c 'luafile tests/ack_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
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

report.finish()
