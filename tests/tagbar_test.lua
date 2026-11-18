-- Run: nvim --headless -c 'luafile tests/tagbar_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local equals = report.equals

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
