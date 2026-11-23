-- Run: tests/run.sh tests/mini-pairs_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local lines_after_keys = dofile(tests_dir .. '/support/typing.lua').lines_after_keys

-- A map cannot see text that the same fed keys type, so put that text in the line first.
local function line_after_keys(text, keys)
  return lines_after_keys('.txt', { text }, keys)[1]
end

-- After nvim_feedkeys, the next message starts without a newline. So feed all keys first, and report the checks after.
local closed = {}
for _, open in ipairs({ '(', '[', '{', '"' }) do
  closed[open] = line_after_keys('', 'i' .. open .. 'x')
end
local jumped = line_after_keys('', 'i(x)')
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
equals('an opening bracket before a word character stays single', before_word, {
  ['('] = '(word',
  ['['] = '[word',
  ['{'] = '{word',
})

report.finish()
