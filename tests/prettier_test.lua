-- Run: nvim --headless -c 'luafile tests/prettier_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

equals(
  'vim-prettier gets its settings before a filetype loads it',
  {
    vim.g['prettier#autoformat_config_present'],
    vim.g['prettier#autoformat_require_pragma'],
    vim.g['prettier#exec_cmd_async'],
    vim.g['prettier#quickfix_enabled'],
  },
  { 1, 0, 1, 0 }
)

report.finish()
