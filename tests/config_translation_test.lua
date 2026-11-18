-- Run: nvim --headless -c 'luafile tests/config_translation_test.lua'
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

for _, mode in ipairs({ 'n', 'v', 'x', 's', 'o' }) do
  local map = vim.fn.maparg('<leader>h', mode, false, true)
  local rhs = vim.fn.maparg('<leader>h', mode)
  check(
    'leader h opens the shortcuts menu in mode ' .. mode,
    rhs == ':Shortcuts<CR>' and map.noremap == 1 and map.silent == 1,
    'expected silent noremap :Shortcuts<CR>, got ' .. vim.inspect(map)
  )
end

local spell_bad = vim.api.nvim_get_hl(0, { name = 'SpellBad', link = false })
local orange = 16753920
check(
  'SpellBad keeps the colorscheme colors and adds an orange undercurl',
  spell_bad.undercurl == true and spell_bad.sp == orange and spell_bad.fg ~= nil,
  'expected undercurl, sp ' .. orange .. ' and a colorscheme fg, got ' .. vim.inspect(spell_bad)
)

local spell_cap = vim.api.nvim_get_hl(0, { name = 'SpellCap', link = false })
check(
  'SpellCap keeps the colorscheme colors and draws a dotted underline, not an undercurl',
  spell_cap.underdotted == true and spell_cap.undercurl == nil
    and spell_cap.fg ~= nil and spell_cap.sp == spell_cap.fg
    and spell_cap.cterm ~= nil and spell_cap.cterm.underline == true,
  'expected underdotted, no undercurl, the colorscheme fg as sp and a cterm underline, got '
    .. vim.inspect(spell_cap)
)

report.finish()
