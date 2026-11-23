-- Run: tests/run.sh tests/config_translation_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

-- Checks the colors of the git signs. Each check name ends with the moment in `when`.
local function check_git_sign_colors(when)
  for group, color in vim.spairs({ GitSignsAdd = '#859900', GitSignsChange = '#b58900', GitSignsDelete = '#dc322f' }) do
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    report.equals(group .. ' draws in ' .. color .. ' ' .. when, fg and ('#%06x'):format(fg), color)
  end
end

-- Checks the colors that the config sets on top of the colorscheme. Each check name ends with the moment in `when`.
local function check_colors(when)
  local spell_bad = vim.api.nvim_get_hl(0, { name = 'SpellBad', link = false })
  local orange = 16753920
  check(
    'SpellBad keeps the colorscheme colors and adds an orange undercurl ' .. when,
    spell_bad.undercurl == true and spell_bad.sp == orange and spell_bad.fg ~= nil,
    'expected undercurl, sp ' .. orange .. ' and a colorscheme fg, got ' .. vim.inspect(spell_bad)
  )

  local spell_cap = vim.api.nvim_get_hl(0, { name = 'SpellCap', link = false })
  check(
    'SpellCap keeps the colorscheme colors and draws a dotted underline, not an undercurl ' .. when,
    spell_cap.underdotted == true and spell_cap.undercurl == nil
      and spell_cap.fg ~= nil and spell_cap.sp ~= nil
      and spell_cap.cterm ~= nil and spell_cap.cterm.underline == true,
    'expected underdotted, no undercurl, a colorscheme fg and sp and a cterm underline, got '
      .. vim.inspect(spell_cap)
  )

  local underlines = {}
  for group, spell_group in vim.spairs({
    DiagnosticUnderlineError = 'SpellBad',
    DiagnosticUnderlineWarn = 'SpellLocal',
    DiagnosticUnderlineInfo = 'SpellRare',
    DiagnosticUnderlineHint = 'SpellRare',
  }) do
    if not vim.deep_equal(vim.api.nvim_get_hl(0, { name = group, link = false }), vim.api.nvim_get_hl(0, { name = spell_group, link = false })) then
      table.insert(underlines, group .. ' ' .. vim.inspect(vim.api.nvim_get_hl(0, { name = group, link = false }), { newline = '', indent = '' }))
    end
  end
  report.equals('a diagnostic underline looks like the matching spell group ' .. when, underlines, {})

  local virtual_text = {}
  local expected_virtual_text = {}
  for severity, diff_group in vim.spairs({ Error = 'DiffDelete', Warn = 'DiffChange', Info = 'DiffText', Hint = 'DiffText' }) do
    virtual_text[severity] = vim.api.nvim_get_hl(0, { name = 'DiagnosticVirtualText' .. severity, link = false })
    expected_virtual_text[severity] = { fg = vim.api.nvim_get_hl(0, { name = diff_group, link = false }).fg or 'a diff color' }
  end
  report.equals('the diagnostic text takes the text color of the matching diff group ' .. when, virtual_text, expected_virtual_text)

  report.equals('floats take the popup menu colors ' .. when, vim.api.nvim_get_hl(0, { name = 'NormalFloat' }), { link = 'Pmenu' })
end

check_colors('at startup')
check_git_sign_colors('at startup')
vim.cmd('colorscheme solarized8')
check_colors('after the colorscheme loads again')
vim.o.background = 'light'
check_colors('after the background changes to light')
vim.o.background = 'dark'
vim.cmd('colorscheme default')
check_git_sign_colors('after another colorscheme loads')

report.finish()
