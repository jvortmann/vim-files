for _, group in ipairs({ 'comment', 'disables', 'editing', 'location', 'make', 'movement', 'quickfix', 'window' }) do
  require('config.keymaps.' .. group)
end

-- The maps of fzf and NERDTree stay VimScript until Step 10 replaces the two plugins.
for _, name in ipairs({ 'fzf', 'nerdtree' }) do
  vim.cmd('source ' .. vim.fn.expand('~/.vim/conf/shortcuts/' .. name .. '.shortcuts'))
end