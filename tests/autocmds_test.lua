-- Run: nvim -i NONE --headless -c 'luafile tests/autocmds_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local group_sizes = {}
for _, group in ipairs({ 'AutoWrite', 'RUBY', 'YankHighlight' }) do
  local ok, autocmds = pcall(vim.api.nvim_get_autocmds, { group = group })
  group_sizes[group] = ok and #autocmds or 0
end
equals(
  'each autocmd sits in its own augroup',
  group_sizes,
  { AutoWrite = 1, RUBY = 8, YankHighlight = 1 }
)

local dir = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(dir, 'p')

local function open(name)
  vim.cmd('silent! edit ' .. vim.fn.fnameescape(dir .. '/' .. name))
end

local function create(name)
  vim.fn.mkdir(vim.fs.dirname(dir .. '/' .. name), 'p')
  vim.fn.writefile({ 'x' }, dir .. '/' .. name)
end

create('changed.txt')
create('other.txt')
open('changed.txt')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'changed' })
open('other.txt')
equals('leaving a changed buffer writes it', vim.fn.readfile(dir .. '/changed.txt'), { 'changed' })

local compilers = {}
for name, existing in vim.spairs({
  ['spec/support/helper.rb'] = true,
  ['order_spec.rb'] = true,
  ['spec/new_spec.rb'] = false,
  ['test/support/helper.rb'] = true,
  ['order_test.rb'] = true,
  ['test/new_test.rb'] = false,
}) do
  if existing then
    create(name)
  else
    vim.fn.mkdir(vim.fs.dirname(dir .. '/' .. name), 'p')
  end
  open(name)
  compilers[name] = vim.b.current_compiler or 'none'
end
equals('ruby spec files get the rspec compiler and test files the rubyunit compiler', compilers, {
  ['spec/support/helper.rb'] = 'rspec',
  ['order_spec.rb'] = 'rspec',
  ['spec/new_spec.rb'] = 'rspec',
  ['test/support/helper.rb'] = 'rubyunit',
  ['order_test.rb'] = 'rubyunit',
  ['test/new_test.rb'] = 'rubyunit',
})

local function yank_highlights()
  local found = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true })) do
    if mark[4].hl_group == 'IncSearch' then
      table.insert(found, mark[2])
    end
  end
  return found
end

open('other.txt')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two' })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_feedkeys('yy', 'mx', false)
local during = yank_highlights()
vim.wait(400)
local after = yank_highlights()
io.stdout:write('\n')
equals('a yank highlights the yanked line with IncSearch', during, { 1 })
equals('the yank highlight ends after its timeout', after, {})

report.finish()
