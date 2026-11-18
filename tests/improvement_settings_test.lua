-- Run: nvim --headless -c 'luafile tests/improvement_settings_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
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

equals('the autoclose setting keeps its misspelled name and the value 0', vim.g.AutoClosePreservDotReg, 0)

equals('tagbar opens 60 columns wide', vim.g.tagbar_width, 60)

local expected_types = vim.fn.readfile(tests_dir .. '/fixtures/tagbar_types.txt')[1]
local types_match = vim.api.nvim_eval(
  "eval(" .. vim.fn.string(expected_types) .. ") ==# filter(copy(g:), 'v:key =~# \"^tagbar_type_\"')"
)
check(
  'tagbar gets the elixir, go, ruby, rust and scala types at startup',
  types_match == 1,
  'got ' .. vim.api.nvim_eval("string(filter(copy(g:), 'v:key =~# \"^tagbar_type_\"'))")
)

report.finish()
