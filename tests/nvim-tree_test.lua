-- Run: tests/run.sh tests/nvim-tree_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local equals = report.equals

-- Returns where the nvim-tree window of the tab is: 'left' when it starts at the first column, 'elsewhere' or 'none'.
local tree_window = [[
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'NvimTree' then
      return vim.fn.win_screenpos(win)[2] == 1 and 'left' or 'elsewhere'
    end
  end
  return 'none'
]]

local editor, job = child.start({ cwd = git_repo.new({ 'one' }, { 'one', 'two' }), files = { 'file.txt' } })
local function run(code, ...)
  return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
end

-- Types the keys, waits until the nvim-tree window is at the expected place, and returns the place it found.
local function after_keys(keys, expected)
  vim.rpcrequest(editor, 'nvim_input', keys)
  local got
  vim.wait(3000, function()
    got = run(tree_window)
    return got == expected
  end)
  return got
end

run([[vim.v.errmsg = '']])
equals('F2 in a new editor opens nvim-tree on the left', after_keys('<F2>', 'left'), 'left')
vim.rpcrequest(editor, 'nvim_input', '<C-w>p')
local left
vim.wait(3000, function()
  left = run([[return { file = vim.fn.expand('%:t'), errmsg = vim.v.errmsg }]])
  return left.file == 'file.txt'
end)
equals('leaving the tree for the file runs the autowrite with no error', left, { file = 'file.txt', errmsg = '' })
-- A second F2 closes the tree, so that the next check starts with no tree window.
after_keys('<F2>', 'none')

-- By now nvim-tree is loaded, so it could take over a folder.
run([[vim.cmd('silent! edit .')]])
local folder
vim.wait(3000, function()
  folder = { filetype = run('return vim.bo.filetype'), tree = run(tree_window) }
  return vim.deep_equal(folder, { filetype = 'netrw', tree = 'none' })
end)
equals(':e . opens the folder in netrw, not in nvim-tree', folder, { filetype = 'netrw', tree = 'none' })

vim.fn.jobstop(job)

local ignoring = git_repo.new({ 'one' }, { 'one' })
git_repo.write(ignoring, {
  ['.gitignore'] = { 'ignored.txt', '.pi/' },
  ['ignored.txt'] = { 'x' },
  ['.pi/settings.json'] = { '{}' },
})
editor, job = child.start({ cwd = ignoring, files = { 'file.txt' } })
-- Returns, for each name, whether a line of the tree ends with it.
local tree_lists = [[
  local text = '\n' .. table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '\n'
  local listed = {}
  for _, name in ipairs({ ... }) do
    listed[name] = text:find('%s' .. vim.pesc(name) .. '\n') ~= nil
  end
  return listed
]]
after_keys('<F2>', 'left')
local listed
vim.wait(3000, function()
  listed = run(tree_lists, 'ignored.txt', '.pi')
  return listed['ignored.txt'] and listed['.pi']
end)
equals(
  'the tree lists the files and folders that git ignores',
  { ['ignored.txt'] = listed['ignored.txt'], ['.pi'] = listed['.pi'] },
  { ['ignored.txt'] = true, ['.pi'] = true }
)
vim.fn.jobstop(job)

local opening = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(opening, 'p')
git_repo.write(opening, { ['file.txt'] = { 'file' }, ['other.txt'] = { 'other' } })

-- Starts an editor on file.txt, runs the Lua of case.setup, opens the tree and types case.keys on the line of
-- other.txt. Then it runs the Lua of case.read, with the result of case.setup, until it returns case.expected or 3
-- seconds pass. It returns the last result of case.read.
local function open_from_tree(case)
  editor, job = child.start({ cwd = opening, files = { 'file.txt' } })
  local before = case.setup and run(case.setup)
  after_keys('<F2>', 'left')
  vim.wait(3000, function()
    return run([[
      for number, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        if line:find('%sother%.txt$') then
          vim.api.nvim_win_set_cursor(0, { number, 0 })
          return true
        end
      end
      return false
    ]])
  end)
  vim.rpcrequest(editor, 'nvim_input', case.keys)
  local got
  vim.wait(3000, function()
    got = run(case.read, before)
    return vim.deep_equal(got, case.expected)
  end)
  vim.fn.jobstop(job)
  return got
end

-- Lua code that returns the number of windows, the kind of split that holds the current window ('row' or 'col'),
-- and the name of the file in that window.
local split = [[
  local function parent(node, win, kind)
    if node[1] == 'leaf' then
      return node[2] == win and kind or nil
    end
    for _, child in ipairs(node[2]) do
      local found = parent(child, win, node[1])
      if found then
        return found
      end
    end
  end
  return {
    windows = #vim.api.nvim_tabpage_list_wins(0),
    split = parent(vim.fn.winlayout(), vim.api.nvim_get_current_win()),
    file = vim.fn.expand('%:t'),
  }
]]

local horizontal = { windows = 3, split = 'col', file = 'other.txt' }
equals(
  '<C-s> in the tree opens the file in a horizontal split',
  open_from_tree({ keys = '<C-s>', read = split, expected = horizontal }),
  horizontal
)
local vertical = { windows = 3, split = 'row', file = 'other.txt' }
equals(
  '<C-v>, a default key of the tree, still opens the file in a vertical split',
  open_from_tree({ keys = '<C-v>', read = split, expected = vertical }),
  vertical
)

equals(
  '<CR> in the tree, with two windows open, opens the file in the last window and asks for no window',
  open_from_tree({
    setup = [[vim.cmd('vsplit') return vim.api.nvim_get_current_win()]],
    keys = '<CR>',
    read = [[return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(...)), ':t')]],
    expected = 'other.txt',
  }),
  'other.txt'
)
report.finish()
