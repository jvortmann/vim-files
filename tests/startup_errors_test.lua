-- Run: nvim --headless -c 'luafile tests/startup_errors_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local known_errors = {
  ['opening a file'] = 'E31: No such mapping',
}

local function leaves_no_error(scenario)
  local got = vim.v.errmsg
  local known = known_errors[scenario] or ''
  local detail = 'got ' .. vim.inspect(got)
  if known ~= '' and got == '' then
    detail = 'the known error ' .. vim.inspect(known) .. ' is gone, remove it from known_errors'
  elseif known ~= '' then
    detail = 'expected only the known error ' .. vim.inspect(known) .. ', ' .. detail
  end
  check(scenario .. ' leaves no new error', got == known, detail)
end

-- lazy.nvim reports a failed plugin load in a scheduled callback. Callbacks run in order, so wait for a later one.
local pending_ran = false
vim.schedule(function() pending_ran = true end)
vim.wait(1000, function() return pending_ran end)
leaves_no_error('a plain start')

vim.v.errmsg = ''
vim.cmd('silent edit ' .. vim.fn.fnameescape(vim.fn.fnamemodify(tests_dir, ':h') .. '/README.md'))
leaves_no_error('opening a file')

report.finish()
