vim.api.nvim_create_autocmd('BufLeave', {
  group = vim.api.nvim_create_augroup('AutoWrite', { clear = true }),
  pattern = '*',
  command = ':update',
})
