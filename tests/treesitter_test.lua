-- Run: nvim --headless -c 'luafile tests/treesitter_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local install_dir = vim.fn.stdpath('data') .. '/site'
local first_rtp_entry = vim.opt.rtp:get()[1]
check(
  'the treesitter parser install dir comes first in runtimepath',
  first_rtp_entry == install_dir,
  'expected ' .. vim.inspect(install_dir) .. ', got ' .. vim.inspect(first_rtp_entry)
)

local start_autocmds = vim.fn.exists('#nvim_treesitter_start#FileType') == 1
  and vim.api.nvim_get_autocmds({ group = 'nvim_treesitter_start', event = 'FileType' })
  or {}
check(
  'one FileType autocmd starts treesitter',
  #start_autocmds == 1,
  'got ' .. vim.inspect(start_autocmds)
)

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
vim.fn.delete(ruby_file)

report.finish()
