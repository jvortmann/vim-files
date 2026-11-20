-- Run: nvim -i NONE --headless -c 'luafile tests/nvim-tree_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')
local equals = report.equals

equals('F2 has a description for which-key', keymaps.undescribed({ '<F2>' }), {})

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

-- The index and file.txt differ, so gitsigns attaches to the file.
equals(
  'gitsigns attaches to the changed file.txt',
  vim.wait(3000, function() return run('return vim.b.gitsigns_status_dict ~= nil') end),
  true
)
run([[vim.v.errmsg = '']])
equals('F2 in a new editor opens nvim-tree on the left', after_keys('<F2>', 'left'), 'left')
equals(
  'gitsigns does not attach to the tree, and the tree shows the devicon of file.txt',
  run([[
    local buf = vim.api.nvim_get_current_buf()
    local icon = require('nvim-web-devicons').get_icon('file.txt')
    local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
    return { gitsigns = vim.b[buf].gitsigns_status_dict ~= nil, icon = text:find(icon, 1, true) ~= nil }
  ]]),
  { gitsigns = false, icon = true }
)
vim.rpcrequest(editor, 'nvim_input', '<C-w>p')
local left
vim.wait(3000, function()
  left = run([[return { file = vim.fn.expand('%:t'), errmsg = vim.v.errmsg }]])
  return left.file == 'file.txt'
end)
equals('leaving the tree for the file runs the autowrite with no error', left, { file = 'file.txt', errmsg = '' })
equals('a second F2 closes nvim-tree', after_keys('<F2>', 'none'), 'none')

-- By now nvim-tree is loaded, so it could take over a folder.
run([[vim.cmd('silent! edit .')]])
local folder
vim.wait(3000, function()
  folder = { filetype = run('return vim.bo.filetype'), tree = run(tree_window) }
  return vim.deep_equal(folder, { filetype = 'netrw', tree = 'none' })
end)
equals(':e . opens the folder in netrw, not in nvim-tree', folder, { filetype = 'netrw', tree = 'none' })

vim.fn.jobstop(job)
report.finish()
