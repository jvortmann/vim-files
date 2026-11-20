-- Mode '' is the mode of :noremap: normal, visual, select and operator-pending.
vim.keymap.set('', '<Leader>lo', ':bo lopen<CR>', { desc = 'Open the location list' })
vim.keymap.set('', '<Leader>lc', ':bo lclose<CR>', { desc = 'Close the location list' })
vim.keymap.set('', '<Leader>lt', ':bo lw<CR>', { desc = 'Open the location list, or close it if empty' })
vim.keymap.set('', '<Leader>ln', ':lnext<CR>', { desc = 'Go to the next location' })
vim.keymap.set('', '<Leader>lp', ':lprev<CR>', { desc = 'Go to the previous location' })
