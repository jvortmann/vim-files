-- Toggle a comment. The maps are recursive, because gc and gcc are maps.
vim.keymap.set('n', '<M-/>', 'gcc', { remap = true, desc = 'Toggle line comment' })
vim.keymap.set('x', '<M-/>', 'gc', { remap = true, desc = 'Toggle selection comment' })
vim.keymap.set('n', '<leader>/', 'gcc', { remap = true, desc = 'Toggle line comment' })
vim.keymap.set('x', '<leader>/', 'gc', { remap = true, desc = 'Toggle selection comment' })
