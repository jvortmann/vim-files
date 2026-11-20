-- Run: nvim --headless -c 'luafile tests/qfenter_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local dir = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(dir, 'p')
local first, second = dir .. '/first.txt', dir .. '/second.txt'
vim.fn.writefile({ 'one' }, first)
vim.fn.writefile({ 'two' }, second)

local function window_of(path)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)) == path then
      return win
    end
  end
end

-- Types the key on the second entry of the quickfix window. Returns how the second file opens next
-- to the first: 'vertical split', 'horizontal split', 'not opened' or 'other'.
local function open_second_entry(key)
  vim.cmd('silent! only')
  vim.cmd('silent! edit ' .. vim.fn.fnameescape(first))
  vim.fn.setqflist({ { filename = first, lnum = 1 }, { filename = second, lnum = 1 } })
  vim.cmd('copen')
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  pcall(vim.api.nvim_feedkeys, vim.keycode(key), 'mx', false)
  vim.cmd('normal! \27')
  local left, right = window_of(first), window_of(second)
  if not left or not right then
    return 'not opened'
  end
  local left_pos, right_pos = vim.fn.win_screenpos(left), vim.fn.win_screenpos(right)
  if left_pos[1] == right_pos[1] then
    return 'vertical split'
  elseif left_pos[2] == right_pos[2] then
    return 'horizontal split'
  end
  return 'other'
end

local expected = {
  ['v'] = 'vertical split',
  ['<C-v>'] = 'vertical split',
  ['<leader><CR>'] = 'vertical split',
  ['s'] = 'horizontal split',
  ['<C-CR>'] = 'horizontal split',
  ['<C-s>'] = 'horizontal split',
  ['<C-x>'] = 'horizontal split',
  ['<leader><Space>'] = 'horizontal split',
}

-- After nvim_feedkeys, the next message starts without a newline. So type all keys first, and report the checks after.
local got = {}
for key in pairs(expected) do
  got[key] = open_second_entry(key)
end
io.stdout:write('\n')

equals('each QFEnter key opens the quickfix entry in its kind of split', got, expected)

report.finish()
