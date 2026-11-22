-- Run: tests/run.sh tests/mini-pairs_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

-- A map cannot see text that the same fed keys type, so put that text in the line first.
local function line_after_keys(text, keys)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(vim.fn.tempname() .. '.txt'))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { text })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'mx', false)
  return vim.api.nvim_get_current_line()
end

-- After nvim_feedkeys, the next message starts without a newline. So feed all keys first, and report the checks after.
local closed = {}
for _, open in ipairs({ '(', '[', '{', '"' }) do
  closed[open] = line_after_keys('', 'i' .. open .. 'x')
end
local jumped = line_after_keys('', 'i(x)')
local backspaced = line_after_keys('', 'i(<BS>x')
local apostrophe = line_after_keys('don', "A't")
local before_word = {}
for _, open in ipairs({ '(', '[', '{' }) do
  before_word[open] = line_after_keys('word', 'i' .. open)
end

equals('an opening character gets its closer, with the cursor between them', closed, {
  ['('] = '(x)',
  ['['] = '[x]',
  ['{'] = '{x}',
  ['"'] = '"x"',
})
equals('a closer typed before the same closer moves over it', jumped, '(x)')
equals('a backspace in an empty pair deletes both characters', backspaced, 'x')
equals('an apostrophe after a letter stays single', apostrophe, "don't")
equals('an opening bracket before a word character stays single', before_word, {
  ['('] = '(word',
  ['['] = '[word',
  ['{'] = '{word',
})

report.finish()
