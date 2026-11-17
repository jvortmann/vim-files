-- Load all autocmd files
local autocmd_path = vim.fn.expand('~/.vim/conf/autocmd')
local autocmd_files = vim.fn.globpath(autocmd_path, '*.autocmd', false, true)

for _, autocmd_file in ipairs(autocmd_files) do
  vim.cmd('source ' .. autocmd_file)
end