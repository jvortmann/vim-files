for _, group in ipairs({ 'comment', 'disables', 'editing', 'location', 'make', 'movement', 'quickfix', 'window' }) do
  require('config.keymaps.' .. group)
end