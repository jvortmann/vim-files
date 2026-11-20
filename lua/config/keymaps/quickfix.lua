-- Mode '' is the mode of :noremap: normal, visual, select and operator-pending.
for _, prefix in ipairs({ '<Leader><Leader>', '<Leader>q' }) do
  vim.keymap.set('', prefix .. 'o', ':bo copen<CR>', { desc = 'Open the quickfix list' })
  vim.keymap.set('', prefix .. 'c', ':bo cclose<CR>', { desc = 'Close the quickfix list' })
  vim.keymap.set('', prefix .. 't', ':bo cw<CR>', { desc = 'Open the quickfix list, or close it if empty' })
  vim.keymap.set('', prefix .. 'n', ':cnext<CR>', { desc = 'Go to the next quickfix entry' })
  vim.keymap.set('', prefix .. 'p', ':cprev<CR>', { desc = 'Go to the previous quickfix entry' })
end

-- These buffer maps win over the global <CR> map of editing.lua, which clears the search highlight.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('config_quickfix_keymaps', { clear = true }),
  pattern = 'quickfix',
  callback = function(event)
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = event.buf, desc = 'Open the entry under the cursor' })
    vim.keymap.set('n', 'h', '<Left>', { buffer = event.buf, desc = 'Move the cursor left' })
  end,
})
