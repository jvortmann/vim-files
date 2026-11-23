-- Run: tests/run.sh tests/comment_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local lines_after_keys = dofile(tests_dir .. '/support/typing.lua').lines_after_keys

local code = { 'local a = 1', 'local b = 2' }

local function after_keys(keys)
  return lines_after_keys('.lua', code, keys)
end

-- After nvim_feedkeys, the next message starts without a newline. So run all keys first, and print the checks after.
local leader_line = after_keys('<leader>/')
local alt_line = after_keys('<M-/>')
local leader_range = after_keys('Vj<leader>/')
local alt_range = after_keys('Vj<M-/>')
local toggled_twice = after_keys('<leader>/<leader>/')

equals('<leader>/ comments the cursor line with the lua commentstring', leader_line, { '-- local a = 1', 'local b = 2' })
equals('<M-/> comments the cursor line with the lua commentstring', alt_line, { '-- local a = 1', 'local b = 2' })
equals('<leader>/ comments a visual range', leader_range, { '-- local a = 1', '-- local b = 2' })
equals('<M-/> comments a visual range', alt_range, { '-- local a = 1', '-- local b = 2' })
equals('a second <leader>/ uncomments the line', toggled_twice, code)

report.finish()
