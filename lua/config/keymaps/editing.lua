-- Mode '' is the mode of :noremap: normal, visual, select and operator-pending. Mode 'v' is visual and select.
-- The maps with remap = true were recursive in the VimScript they replace, and they stay so.

-- Move lines with Option-Shift-Down or Option-Shift-j, and up with Option-Shift-Up or Option-Shift-k.
for _, lhs in ipairs({ '<M-S-Down>', '<M-S-j>' }) do
  vim.keymap.set('n', lhs, ':m+<CR>==', { remap = true, silent = true, desc = 'Move the line down' })
  vim.keymap.set('i', lhs, '<Esc>:m+<CR>==gi', { remap = true, silent = true, desc = 'Move the line down' })
  vim.keymap.set('v', lhs, ":m'>+<CR>gv=gv", { remap = true, silent = true, desc = 'Move the selected lines down' })
end
for _, lhs in ipairs({ '<M-S-Up>', '<M-S-k>' }) do
  vim.keymap.set('n', lhs, ':m-2<CR>==', { remap = true, silent = true, desc = 'Move the line up' })
  vim.keymap.set('i', lhs, '<Esc>:m-2<CR>==gi', { remap = true, silent = true, desc = 'Move the line up' })
  vim.keymap.set('v', lhs, ':m-2<CR>gv=gv', { remap = true, silent = true, desc = 'Move the selected lines up' })
end

vim.keymap.set('', '<M-S-d>', 'Y`]p', { desc = 'Duplicate the line' })
vim.keymap.set('', '<leader>d', 'Y`]p', { desc = 'Duplicate the line' })
vim.keymap.set('', '<M-a>', 'ggVG', { desc = 'Select the whole buffer' })

-- Keep the selection after a change of indent.
vim.keymap.set('v', '>', '>gv', { desc = 'Indent, and keep the selection' })
vim.keymap.set('v', '<', '<gv', { desc = 'Unindent, and keep the selection' })

vim.keymap.set('n', 'Y', 'y$', { desc = 'Yank to the end of the line' })
vim.keymap.set('n', '<CR>', ':noh<CR>', { remap = true, silent = true, desc = 'Clear the search highlight' })
