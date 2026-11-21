-- Run: nvim -i NONE --headless -c 'luafile tests/airline_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local screen = dofile(tests_dir .. '/support/screen.lua')

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

local folder = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(folder, 'p')
vim.fn.writefile({ 'one', 'two' }, folder .. '/file.txt')
local pane = screen.start({ cwd = folder, args = { 'file.txt' }, width = 100 })
pane.run([[
  local server = dofile(...)
  local error = { range = { start = { line = 1, character = 0 }, ['end'] = { line = 1, character = 3 } }, severity = 1, message = 'bad' }
  vim.lsp.start({ name = 'fake', root_dir = vim.fn.getcwd(), cmd = server.cmd({ initialize = { capabilities = { textDocumentSync = 1 } } }, { error }) })
]], tests_dir .. '/support/lsp_server.lua')
local statusline
vim.wait(5000, function()
  local rows = pane.rows()
  statusline = vim.trim(rows[#rows - 2] or '')
  return statusline:find('E:1(L2)', 1, true) ~= nil
end)
pane.stop()
report.check('airline shows the count of errors from the language server', statusline:find('E:1(L2)', 1, true) ~= nil, 'got ' .. vim.inspect(statusline))

report.finish()
