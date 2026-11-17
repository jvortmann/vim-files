-- Default options configuration
vim.cmd('filetype indent plugin on')

-- Define shell to avoid problems
vim.opt.shell = 'zsh'

-- Search settings
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.gdefault = true
vim.opt.showmatch = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.inccommand = 'nosplit'

-- Enable auto write
vim.opt.autowriteall = true

-- Automatically reload files if they were modified outside vim
vim.opt.autoread = true

-- Set the buffer to become hidden instead of preventing the user from changing to another buffer
vim.opt.hidden = true

-- Consistent indenting options
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true

-- Set auto indent and smart indent
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Enable syntax highlight
vim.cmd('syntax enable')

-- Allow backspacing over everything in insert mode
vim.opt.backspace = {'indent', 'eol', 'start'}

-- Set the history to display more items
vim.opt.history = 200

-- Set the undo to have a thousand entries
vim.opt.undolevels = 1000

-- Folding settings
vim.opt.foldenable = false  -- disable folding

-- Improve the autocomplete menu
vim.opt.completeopt = {'longest', 'menuone'}

-- Add spell to autocomplete
vim.opt.complete:append('kspell')

-- Disable going to the menu when pressing alt
vim.opt.winaltkeys = 'no'

-- Disable swap files
vim.opt.swapfile = false

-- Change the invisible chars
vim.opt.listchars = {
  tab = '▸ ',
  eol = '¬',
  extends = '❯',
  precedes = '❮',
  trail = '⌴'
}

vim.opt.showbreak = '↪  '
vim.opt.fillchars = {
  diff = '⣿',
  vert = '│'
}

-- Set clipboard without the need for "+"
vim.opt.clipboard = 'unnamed'

-- Disables the showing of current mode on the command line
vim.opt.showmode = false

-- Set split to open in a more natural setup
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Add gem.tags to the list of tag files to look for
vim.opt.tags:append('gem.tags')

-- Set lazyredraw so macros run faster and speed vim up
vim.opt.lazyredraw = true

-- Load the status line
require('config.statusline')

-- Make status bar always be shown
vim.opt.laststatus = 2

-- Enable modeline for 3 lines (reading configs on top/bottom of file)
vim.opt.modeline = true
vim.opt.modelines = 3

-- Reduce update time to just 50ms
vim.opt.updatetime = 50

-- Set no fix height or width
vim.opt.winfixheight = false
vim.opt.winfixwidth = false