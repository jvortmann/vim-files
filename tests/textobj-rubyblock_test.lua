-- Run: nvim --headless -c 'luafile tests/textobj-rubyblock_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local code = { 'class Order', '  def total', '    1', '  end', 'end' }

local function after_normal(keys, path)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(path or vim.fn.tempname() .. '.rb'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, code)
  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  vim.cmd('normal ' .. keys)
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local script = vim.fn.tempname() .. '/bin/setup'
vim.fn.mkdir(vim.fs.dirname(script), 'p')
vim.fn.writefile({ '#!/usr/bin/env ruby' }, script)
equals(
  'ir works in a first buffer that only its shebang marks as ruby',
  after_normal('dir', script),
  { 'class Order', '  def total', '  end', 'end' }
)
equals('ir deletes the inside of the ruby block', after_normal('dir'), { 'class Order', '  def total', '  end', 'end' })
equals('ar deletes the whole ruby block', after_normal('dar'), { 'class Order', 'end' })

report.finish()
