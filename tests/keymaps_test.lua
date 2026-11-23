-- Run: tests/run.sh tests/keymaps_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local child = dofile(tests_dir .. '/support/editor.lua')

local alt_a = {}
for _, mode in ipairs({ 'n', 'v', 's', 'o' }) do
  alt_a[mode] = vim.fn.maparg('<M-a>', mode)
end
equals('<M-a> has no map, so it stays free for Herdr', alt_a, { n = '', v = '', s = '', o = '' })

-- The quickfix window gets its own <CR>, so the global <CR> map, which clears the search highlight, does not run there.
local dir = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(dir, 'p')
vim.fn.writefile({ 'one', 'two', 'three' }, dir .. '/first.txt')
vim.fn.writefile({ 'second' }, dir .. '/second.txt')
local editor, job = child.start({ cwd = dir, files = { 'first.txt' } })
local function run(code)
  return vim.rpcrequest(editor, 'nvim_exec_lua', code, {})
end
run([[
  vim.fn.setqflist({ { filename = 'first.txt', lnum = 1 }, { filename = 'second.txt', lnum = 1 } })
  vim.cmd('copen')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
]])
vim.rpcrequest(editor, 'nvim_input', '<CR>')
local opened
vim.wait(2000, function()
  opened = run("return { vim.fn.expand('%:t'), vim.bo.buftype }")
  return vim.deep_equal(opened, { 'second.txt', '' })
end, 10)
vim.fn.jobstop(job)
equals('<CR> in the quickfix window opens the entry under the cursor', opened, { 'second.txt', '' })

report.finish()
