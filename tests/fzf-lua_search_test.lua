-- Run: nvim -i NONE --headless -c 'luafile tests/fzf-lua_search_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local equals = report.equals

local config = require('fzf-lua.config')

local repo = git_repo.new({ 'needle' }, { 'needle' })
git_repo.write(repo, {
  ['.gitignore'] = { 'build/' },
  ['node_modules/pkg/index.js'] = { 'needle' },
})

-- rg and fd read the global git ignore file of the user, which can list node_modules. An empty home hides it.
local empty_home = vim.fn.tempname()
vim.fn.mkdir(empty_home, 'p')

-- Runs the shell command of a picker in the repo, and returns the sorted names of the files that it lists.
local function listed_files(command)
  local output = vim.system({ 'sh', '-c', command }, {
    cwd = repo,
    env = { HOME = empty_home, XDG_CONFIG_HOME = empty_home },
    stdin = false,
    text = true,
  }):wait().stdout
  local files = {}
  for line in output:gsub('\27%[[%d;]*m', ''):gmatch('[^\n]+') do
    table.insert(files, line:match('^[^:]+'))
  end
  files = vim.list.unique(files)
  table.sort(files)
  return files
end

local grep_opts = config.normalize_opts({}, 'grep')
equals(
  'the grep pickers skip a node_modules folder that .gitignore does not list',
  listed_files(require('fzf-lua.make_entry').get_grep_cmd(grep_opts, 'needle', false)),
  { 'file.txt' }
)

local files_cmd = require('fzf-lua.providers.files').get_files_cmd
equals(
  'the files picker skips a node_modules folder that .gitignore does not list',
  listed_files(files_cmd(config.normalize_opts({}, 'files'))),
  { '.gitignore', 'file.txt' }
)

-- The files picker runs rg when fd is not installed.
local executable = vim.fn.executable
vim.fn.executable = function(name)
  return (name == 'fd' or name == 'fdfind') and 0 or executable(name)
end
local rg_files_cmd = files_cmd(config.normalize_opts({}, 'files'))
vim.fn.executable = executable
equals(
  'without fd, the files picker skips a node_modules folder that .gitignore does not list',
  listed_files(rg_files_cmd),
  { '.gitignore', 'file.txt' }
)

report.finish()
