local group = vim.api.nvim_create_augroup('RUBY', { clear = true })

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  group = group,
  pattern = { '*/spec/**/*.rb', '*_spec.rb' },
  command = 'compiler rspec',
})
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  group = group,
  pattern = { '*/test/**/*.rb', '*_test.rb' },
  command = 'compiler rubyunit',
})
