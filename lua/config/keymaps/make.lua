-- Mode '' is the mode of :noremap: normal, visual, select and operator-pending.
vim.keymap.set('', '<F5>', ':make<CR>', { desc = "Run 'makeprg'" })
vim.keymap.set('', '<F6>', ':make %<CR>', { desc = "Run 'makeprg' on the current file" })
