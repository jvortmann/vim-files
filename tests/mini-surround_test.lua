-- Run: nvim -i NONE --headless -c 'luafile tests/mini-surround_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local function line_after_keys(text, keys)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(vim.fn.tempname() .. '.txt'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'mx', false)
  return vim.api.nvim_get_current_line()
end

-- The tag prompt prints with no newline. So run every key first, end the line, then report.
local closing = line_after_keys('word', 'ysiw)')
local opening = line_after_keys('word', 'ysiw(')
local quoted = line_after_keys('word', 'ysiw"')
local tagged = line_after_keys('word', 'ysiwtem<CR>')
local replaced = line_after_keys('"word"', 'cs"\'')
local retagged = line_after_keys('<em>word</em>', 'csttb<CR>')
local deleted = line_after_keys('(word)', 'ds(')
local deleted_ahead = line_after_keys('x (word)', 'ds(')
local whole_line = line_after_keys('a short line', 'yss)')
local selection = line_after_keys('one two', 'viwS)')
local repeated_add = line_after_keys('one two', 'ysiw)W.')
local repeated_delete = line_after_keys('(one) (two)', 'ds(W.')
io.stdout:write('\n')

equals('ys with a closing bracket wraps a word with no spaces', closing, '(word)')
equals('ys with an opening bracket wraps a word with inner spaces', opening, '( word )')
equals('ys with a quote wraps a word in quotes', quoted, '"word"')
equals('ys with t wraps a word in a tag', tagged, '<em>word</em>')
equals('cs replaces one surrounding with another', replaced, "'word'")
equals('cs with t replaces a tag', retagged, '<b>word</b>')
equals('ds deletes a surrounding', deleted, 'word')
equals('ds finds the next surrounding when the cursor is before it', deleted_ahead, 'x word')
equals('no visual map starts with y, so y yanks at once', vim.fn.mapcheck('y', 'x'), '')
equals('yss wraps the whole line', whole_line, '(a short line)')
equals('S in visual mode wraps the selection', selection, '(one) two')
equals('a dot repeats ys on the next word', repeated_add, '(one) (two)')
equals('a dot repeats ds on the next surrounding', repeated_delete, 'one two')

report.finish()
