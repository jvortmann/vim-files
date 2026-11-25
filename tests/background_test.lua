-- Run: tests/run.sh tests/background_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')

local pane = screen.start({ background = '#fdf6e3' })
report.equals(
  'in a light terminal, Neovim starts with a light background and the solarized light colors',
  pane.run("return { vim.o.background, ('#%06x'):format(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg or 0) }"),
  { 'light', '#fdf6e3' }
)
pane.stop()

report.finish()
