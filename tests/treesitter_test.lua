-- Run: tests/run.sh tests/treesitter_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

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

local ruby_file = vim.fn.tempname() .. '.rb'
vim.fn.writefile({ 'class Greeter', '  def hello', '  end', 'end' }, ruby_file)
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
