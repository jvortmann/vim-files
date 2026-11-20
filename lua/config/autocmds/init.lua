for _, name in ipairs({ 'autowrite', 'ruby', 'yank' }) do
  require('config.autocmds.' .. name)
end