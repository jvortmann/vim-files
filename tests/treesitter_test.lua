-- Run: tests/run.sh tests/treesitter_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local child_stdout = dofile(tests_dir .. '/support/child_stdout.lua')

-- Returns the languages that the spec installs. A stand-in for nvim-treesitter takes the list, so nothing installs.
local function languages_in_spec()
  local plugin = package.loaded['nvim-treesitter']
  local languages
  package.loaded['nvim-treesitter'] = { setup = function() end, install = function(list) languages = list end }
  local ok, err = pcall(require('plugins.treesitter')[1].config)
  package.loaded['nvim-treesitter'] = plugin
  assert(ok, err)
  return languages or {}
end

-- Checks that each { row, col, name } of expected has a highlight capture of that name.
local function check_captures(name, buf, expected)
  vim.treesitter.get_parser(buf):parse(true)
  local found, ok = {}, true
  for index, position in ipairs(expected) do
    local captures = vim.treesitter.get_captures_at_pos(buf, position[1], position[2])
    found[index] = vim.tbl_map(function(capture) return capture.capture end, captures)
    ok = ok and vim.list_contains(found[index], position[3])
  end
  check(name, ok, 'got ' .. vim.inspect(found))
end

-- Starts a child Neovim with this config and args. Returns a function that waits for the child and returns the filetype
-- of its current buffer and true or false for treesitter highlighting, such as "ruby true".
local function child_highlight(args)
  return child_stdout(vim.list_extend(args, {
    '+lua io.stdout:write(vim.bo.filetype .. " " .. tostring(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil))',
    '+qa!',
  }))
end

local ruby_file = vim.fn.tempname() .. '.rb'
vim.fn.writefile({ 'class Greeter', '  def hello', '  end', 'end' }, ruby_file)
local first_buffers = {
  { 'a ruby file as the argument gets treesitter highlighting', child_highlight({ ruby_file }), 'ruby true' },
  { ':help as the first buffer gets treesitter highlighting', child_highlight({ '+help' }), 'help true' },
  { ':setf ruby in the empty first buffer gets treesitter highlighting', child_highlight({ '+setf ruby' }), 'ruby true' },
}
for _, first in ipairs(first_buffers) do
  report.equals(first[1], first[2](), first[3])
end
vim.cmd('silent edit ' .. vim.fn.fnameescape(ruby_file))
local ruby_buf = vim.api.nvim_get_current_buf()
local treesitter_indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
check(
  'opening a ruby file sets the treesitter indentexpr',
  vim.bo[ruby_buf].indentexpr == treesitter_indentexpr,
  'got ' .. vim.inspect(vim.bo[ruby_buf].indentexpr)
)
check_captures(
  'a ruby buffer gets treesitter highlight captures',
  ruby_buf,
  { { 0, 0, 'keyword.type' }, { 0, 6, 'type' }, { 1, 2, 'keyword.function' } }
)
vim.fn.delete(ruby_file)

local toml_file = vim.fn.tempname() .. '.toml'
vim.fn.writefile({ 'name = "demo"' }, toml_file)
vim.cmd('silent edit ' .. vim.fn.fnameescape(toml_file))
local toml_buf = vim.api.nvim_get_current_buf()
check_captures('a toml buffer gets treesitter highlight captures', toml_buf, { { 0, 1, 'property' } })
vim.fn.delete(toml_file)

local unreadable_languages = vim.tbl_filter(function(language)
  local path = vim.api.nvim_get_runtime_file('queries/' .. language .. '/highlights.scm', false)[1]
  local file = path and io.open(path, 'r')
  if file then
    file:close()
  end
  return not file
end, languages_in_spec())
report.equals('each language of the spec has a readable highlights query', unreadable_languages, {})

report.finish()
