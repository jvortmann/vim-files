-- Run: tests/run.sh tests/mini-surround_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local child_stdout = dofile(tests_dir .. '/support/child_stdout.lua')
local lines_after_keys = dofile(tests_dir .. '/support/typing.lua').lines_after_keys

local function line_after_keys(text, keys)
  return lines_after_keys('.txt', { text }, keys)[1]
end

-- Starts a child Neovim with this config, types keys there on a line of text, and returns a function that waits for
-- the child and returns the line. Each child is a fresh editor, so the keys are the first press of their map.
local function first_press(text, keys)
  return child_stdout({
    '+lua vim.api.nvim_buf_set_lines(0, 0, -1, false, { ' .. vim.inspect(text) .. ' })',
    '+lua vim.api.nvim_feedkeys(vim.keycode(' .. vim.inspect(keys) .. '), "mx", false)',
    '+lua io.stdout:write(vim.api.nvim_get_current_line())',
    '+qa!',
  })
end

local first_presses = {
  { 'yss wraps the whole line on its first press', first_press('a short line', 'yss)'), '(a short line)' },
  { 'S in visual mode wraps the selection on its first press', first_press('one two', 'viwS)'), '(one) two' },
  { 'ds deletes a surrounding on its first press', first_press('(word)', 'ds('), 'word' },
  { 'cs replaces a surrounding on its first press', first_press('"word"', 'cs"\''), "'word'" },
}

local deleted_ahead = line_after_keys('x (word)', 'ds(')

equals('ds finds the next surrounding when the cursor is before it', deleted_ahead, 'x word')
equals('no visual map starts with y, so y yanks at once', vim.fn.mapcheck('y', 'x'), '')
for _, first in ipairs(first_presses) do
  equals(first[1], first[2](), first[3])
end

report.finish()
