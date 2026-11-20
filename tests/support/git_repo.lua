local M = {}

-- Makes a git repo with file.txt in the index as `indexed`, then writes `edited` to the file on disk.
-- gitsigns compares the file with the index, so the repo needs no commit. It returns the folder of the repo.
function M.new(indexed, edited)
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, 'p')
  vim.system({ 'git', '-C', dir, 'init', '-q' }, { stdin = false }):wait()
  vim.fn.writefile(indexed, dir .. '/file.txt')
  vim.system({ 'git', '-C', dir, 'add', 'file.txt' }, { stdin = false }):wait()
  vim.fn.writefile(edited, dir .. '/file.txt')
  return dir
end

return M
