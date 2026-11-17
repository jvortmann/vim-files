-- Plugin initialization
-- This will be completely rewritten in Step 2 to use lazy.nvim
-- For now, keeping the vim-plug approach converted to Lua

-- Install vim-plug if not present
local plug_install_path = vim.fn.expand('~/.vim/autoload/plug.vim')
if vim.fn.filereadable(plug_install_path) == 0 then
  print('Setting up vim-plug.')
  vim.fn.system({
    'curl', '-fLo', plug_install_path, '--create-dirs',
    'https://raw.github.com/junegunn/vim-plug/master/plug.vim'
  })
  print('Curl plug.vim into autoload')
end

-- Initialize vim-plug
vim.call('plug#begin', '~/.vim/bundle')

-- Source home and local plugins, otherwise fallback to default
local home_plugins = vim.fn.expand('~/.vim.plugins')
local local_plugins = '.vim.plugins'

if vim.fn.filereadable(home_plugins) == 1 or vim.fn.filereadable(local_plugins) == 1 then
  if vim.fn.filereadable(home_plugins) == 1 then
    vim.cmd('source ' .. home_plugins)
  end
  if vim.fn.filereadable(local_plugins) == 1 then
    vim.cmd('source ' .. local_plugins)
  end
else
  vim.cmd('source ~/.vim/conf/plugins/vim.plugins.default')
end

vim.call('plug#end')

-- Required to call Shortcut command during initialization
vim.cmd('runtime plugin/shortcut.vim')

-- Source plugin settings
require('config.plugins.settings.init')