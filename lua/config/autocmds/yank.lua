vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  pattern = '*',
  command = 'lua vim.highlight.on_yank {higroup="IncSearch", timeout=150, on_visual=true}',
})
