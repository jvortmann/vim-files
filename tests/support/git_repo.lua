local M = {}

local git

-- Makes a git repo with file.txt in the index as `indexed`, then writes `edited` to the file on disk.
-- gitsigns compares the file with the index, so the repo needs no commit. It returns the folder of the repo.
function M.new(indexed, edited)
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, 'p')
  git(dir, { 'init', '-q' })
  vim.fn.writefile(indexed, dir .. '/file.txt')
  git(dir, { 'add', 'file.txt' })
  vim.fn.writefile(edited, dir .. '/file.txt')
  return dir
end

-- Writes files, a map of names to lines, into dir. It makes the folders that a name needs.
function M.write(dir, files)
  for name, lines in pairs(files) do
    vim.fn.mkdir(vim.fs.dirname(dir .. '/' .. name), 'p')
    vim.fn.writefile(lines, dir .. '/' .. name)
  end
end

-- Makes an empty folder and returns it. rg and fd read the global git ignore file of the user, which can list node_modules.
-- A test that sets HOME and XDG_CONFIG_HOME to this folder hides that file.
function M.empty_home()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  return dir
end

-- Runs git with args in dir. It throws an error when git fails, or when it runs longer than 10 seconds.
-- A git whose child holds the output pipes fails after 20 seconds.
function git(dir, args)
  local command = vim.list_extend({ 'git', '-C', dir }, args)
  local result = vim.system(command, { stdin = false, text = true }):wait(10000)
  local name = table.concat(command, ' ')
  -- After the kill, wait() waits 10 more seconds. It then returns no result when a child of git still holds the output pipes.
  if not result or result.code == 124 then
    error(name .. ' timed out after 10 s')
  elseif result.code ~= 0 then
    error(('%s exited with %d: %s'):format(name, result.code, result.stderr))
  end
end

return M
