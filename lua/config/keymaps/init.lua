for _, group in ipairs({ 'comment', 'disables', 'editing', 'location', 'lsp', 'make', 'movement', 'quickfix', 'window' }) do
  require('config.keymaps.' .. group)
end