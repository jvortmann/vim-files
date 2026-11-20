-- Run: nvim -i NONE --headless -c 'luafile tests/airline_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

equals(
  'airline shows no separators, no branch, no hunks and no utf-8[unix] encoding',
  {
    vim.g.airline_powerline_fonts,
    vim.g.airline_left_sep,
    vim.g.airline_right_sep,
    vim.g['airline#extensions#branch#enabled'],
    vim.g['airline#extensions#hunks#enabled'],
    vim.g['airline#parts#ffenc#skip_expected_string'],
  },
  { 0, '', '', 0, 0, 'utf-8[unix]' }
)
equals(
  'airline loads without its branch and hunks extensions',
  { vim.fn.exists('*airline#extensions#branch#init'), vim.fn.exists('*airline#extensions#hunks#init') },
  { 0, 0 }
)

report.finish()
