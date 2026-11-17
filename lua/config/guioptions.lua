-- GUI and visual options
vim.opt.termguicolors = true
vim.g.t_8f = '\27[38;2;%lu;%lu;%lum'
vim.g.t_8b = '\27[48;2;%lu;%lu;%lum'

vim.opt.background = 'dark'
-- Try to set colorscheme, fallback gracefully if not available
local ok, _ = pcall(vim.cmd, 'colorscheme solarized8')
if not ok then
  pcall(vim.cmd, 'colorscheme default')
end

vim.opt.number = true
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

-- Set spellcheck settings
vim.cmd('highlight SpellBad term=underline gui=undercurl guisp=Orange')