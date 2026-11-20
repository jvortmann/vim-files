for _, group in ipairs({ 'comment', 'disables', 'editing', 'location', 'make', 'movement', 'quickfix', 'window' }) do
  require('config.keymaps.' .. group)
end

-- The maps of NERDTree stay VimScript until Step 10 replaces the plugin.
vim.cmd('source ' .. vim.fn.expand('~/.vim/conf/shortcuts/nerdtree.shortcuts'))