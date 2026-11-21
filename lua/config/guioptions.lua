-- GUI and visual options
vim.opt.termguicolors = true

vim.opt.background = 'dark'
-- A colorscheme load replaces these colors. A change of 'background' loads the colorscheme again.
-- The autocmd sets the colors after each load. It sits before the first `colorscheme` call, so startup sets them too.
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('config_colors', { clear = true }),
  callback = function()
    -- Set spellcheck settings
    vim.cmd('highlight SpellBad term=underline gui=undercurl guisp=Orange')
    vim.cmd('highlight SpellCap term=underline gui=underdotted')
    -- solarized8 sets no NormalFloat, so floats take the popup menu colors
    vim.api.nvim_set_hl(0, 'NormalFloat', { link = 'Pmenu' })
    -- The git signs take the solarized green, yellow and red
    vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = '#859900' })
    vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = '#b58900' })
    vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = '#dc322f' })
    -- solarized8 sets no diagnostic colors, so signs take the diff colors and underlines take the spell colors
    vim.api.nvim_set_hl(0, 'DiagnosticSignError', { link = 'DiffDelete' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignWarn', { link = 'DiffChange' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignInfo', { link = 'DiffText' })
    vim.api.nvim_set_hl(0, 'DiagnosticSignHint', { link = 'DiffText' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { link = 'SpellBad' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { link = 'SpellLocal' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { link = 'SpellRare' })
    vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', { link = 'SpellRare' })
  end,
})
-- Try to set colorscheme, fallback gracefully if not available
local ok, _ = pcall(vim.cmd, 'colorscheme solarized8')
if not ok then
  pcall(vim.cmd, 'colorscheme default')
end

vim.opt.number = true
require('config.statuscolumn').setup()
vim.opt.tabstop = 2
vim.opt.mouse = 'a'
vim.opt.ruler = true
vim.opt.title = true
vim.opt.cursorline = true
vim.opt.synmaxcol = 256
vim.cmd('syntax sync minlines=256')

-- Set the space from the current line when scrolling
vim.opt.scrolloff = 3

-- Command-line completion shows a list of matches
vim.opt.wildmenu = true