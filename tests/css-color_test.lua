-- Run: nvim --headless -c 'luafile tests/css-color_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

check(
  'the vim-css-color updatetime setting is set at startup',
  vim.g.cssColorVimDoNotMessMyUpdatetime == 1,
  'got ' .. vim.inspect(vim.g.cssColorVimDoNotMessMyUpdatetime)
)

report.finish()
