-- Set the initial configuration
require('config.init')

-- Set the configuration that has precedence (as mapleader)
require('config.first')

-- Load the plugins
require('config.plugins.init')

-- Load the default options
require('config.defaults')

-- Set how diagnostics show
require('config.diagnostics')

-- Load the autocmd options
require('config.autocmds.init')

-- Save the session for Herdr
require('config.herdr_session').setup()

-- Load the gui options
require('config.guioptions')

-- Load the keymaps
require('config.keymaps.init')

-- Load local vimrc file if it exists
if vim.fn.filereadable(vim.fn.expand("$HOME/.vimrc.local")) == 1 then
  vim.cmd('source $HOME/.vimrc.local')
end

-- Then loads after/plugin/force_configs.vim
-- And then your local ~/.vimrc.force for configs
-- that needs to be setup last