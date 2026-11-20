-- Mode '' is the mode of :noremap: normal, visual, select and operator-pending.
-- replace_keycodes = false keeps the setting of the VimScript map that this map replaces.
vim.keymap.set('', '<Space><Space>', '":vertical res<CR>:res<CR>"', {
  expr = true,
  replace_keycodes = false,
  silent = true,
  desc = 'Maximize the window',
})
vim.keymap.set('', '<Space>=', '<C-w>=', { desc = 'Equalize the window sizes' })
vim.keymap.set('', '<Space>_', '<C-w>_', { desc = 'Maximize the window height' })
vim.keymap.set('', '<Space><Bar>', '<C-w><Bar>', { desc = 'Maximize the window width' })
vim.keymap.set('', '<Space>o', '<C-w>o', { desc = 'Close all other windows' })
vim.keymap.set('', '<Space>r', '<C-w>r', { desc = 'Rotate the windows' })
