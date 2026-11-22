-- Run: nvim -i NONE --headless -c 'luafile tests/grep_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local equals = report.equals

local repo = git_repo.new({ 'first', '  needle' }, { 'first', '  needle' })
git_repo.write(repo, {
  ['.gitignore'] = { 'build/' },
  ['.hidden/x.txt'] = { 'needle' },
  ['node_modules/pkg/index.js'] = { 'needle' },
  ['.git/info/notes.txt'] = { 'needle' },
  ['vendor/lib.rb'] = { 'needle' },
  ['lib/vendor/x.rb'] = { 'needle' },
  ['build/out.txt'] = { 'needle' },
})
vim.cmd.cd(vim.fn.fnameescape(repo))

local empty_home = git_repo.empty_home()
local home, config_home = vim.env.HOME, vim.env.XDG_CONFIG_HOME
vim.env.HOME, vim.env.XDG_CONFIG_HOME = empty_home, empty_home
vim.cmd('silent grep needle')
vim.env.HOME, vim.env.XDG_CONFIG_HOME = home, config_home
local results = vim.fn.getqflist()

local function relative_name(item)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ':.')
end

local files = vim.list.unique(vim.tbl_map(relative_name, results))
table.sort(files)
equals(
  ':grep lists normal and hidden files, and skips node_modules, .git, the root vendor and ignored files',
  files,
  { '.hidden/x.txt', 'file.txt', 'lib/vendor/x.rb' }
)

local file_match = vim.tbl_filter(function(item)
  return relative_name(item) == 'file.txt'
end, results)[1] or {}
equals(':grep puts the line and column of a match in the quickfix list', { file_match.lnum, file_match.col }, { 2, 3 })

report.finish()
