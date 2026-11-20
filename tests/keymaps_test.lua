-- Run: nvim --headless -c 'luafile tests/keymaps_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local child = dofile(tests_dir .. '/support/editor.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')

equals('every comment map has a description', keymaps.undescribed({ '<M-/>', '<leader>/' }, { 'n', 'x' }), {})
equals('every map that turns a key off has a description', keymaps.undescribed({ '<F1>', 'Q', 'K' }, { 'n' }), {})
equals('every movement map has a description', keymaps.undescribed({ '<S-Up>', '<S-Down>' }), {})
equals(
  'every window map has a description',
  keymaps.undescribed({ '<Space><Space>', '<Space>=', '<Space>_', '<Space><Bar>', '<Space>o', '<Space>r' }),
  {}
)
equals(
  'every location list map has a description',
  keymaps.undescribed({ '<leader>lo', '<leader>lc', '<leader>lt', '<leader>ln', '<leader>lp' }),
  {}
)
equals(
  'every quickfix map has a description',
  keymaps.undescribed({
    '<leader><leader>o', '<leader><leader>c', '<leader><leader>t', '<leader><leader>n', '<leader><leader>p',
    '<leader>qo', '<leader>qc', '<leader>qt', '<leader>qn', '<leader>qp',
  }),
  {}
)
vim.fn.setqflist({ { filename = vim.fn.tempname(), lnum = 1 } })
vim.cmd('copen')
equals('the maps of the quickfix window have a description', keymaps.undescribed({ '<CR>', 'h' }, { 'n' }), {})
local quickfix_maps = {}
for _, lhs in ipairs({ '<CR>', 'h' }) do
  local map = vim.fn.maparg(lhs, 'n', false, true)
  quickfix_maps[lhs] = { map.rhs, map.buffer, map.noremap }
end
equals(
  'the quickfix window maps <CR> and h to the built-in keys',
  quickfix_maps,
  { ['<CR>'] = { '<CR>', 1, 1 }, h = { '<Left>', 1, 1 } }
)
vim.cmd('cclose')
equals('every make map has a description', keymaps.undescribed({ '<F5>', '<F6>' }), {})
equals(
  'every editing map has a description',
  vim.list_extend(
    vim.list_extend(
      keymaps.undescribed({ '<M-S-Down>', '<M-S-j>', '<M-S-Up>', '<M-S-k>' }, { 'n', 'i', 'x', 's' }),
      keymaps.undescribed({ '<M-S-d>', '<leader>d', '<M-a>' })
    ),
    vim.list_extend(keymaps.undescribed({ '>', '<' }, { 'x', 's' }), keymaps.undescribed({ 'Y', '<CR>' }, { 'n' }))
  ),
  {}
)

local dir = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(dir, 'p')
vim.fn.writefile({ 'one', 'two', 'three' }, dir .. '/first.txt')
vim.fn.writefile({ 'second' }, dir .. '/second.txt')

-- Starts an editor on first.txt, runs `case.setup`, and types `case.keys`. After `case.settle` milliseconds, it
-- runs `case.read` until the result equals the expected one or 2 seconds pass. It returns the last result and
-- the expected one. That is `case.expected`, or the result of `case.expected_from`, which runs before the keys.
local function typed(case)
  local editor, job = child.start({ cwd = dir, files = { 'first.txt' } })
  local function run(code)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, {})
  end
  if case.setup then
    run(case.setup)
  end
  local expected = case.expected or run(case.expected_from)
  vim.rpcrequest(editor, 'nvim_input', case.keys)
  vim.wait(case.settle or 0)
  local got
  vim.wait(2000, function()
    got = run(case.read)
    return vim.deep_equal(got, expected)
  end)
  vim.fn.jobstop(job)
  return got, expected
end

local lines = 'return vim.api.nvim_buf_get_lines(0, 0, -1, false)'

local got, expected = typed({ keys = '<M-S-j>', read = lines, expected = { 'two', 'one', 'three' } })
equals('<M-S-j> moves the line down in normal mode', got, expected)

got, expected = typed({
  keys = 'i<M-S-j>',
  read = 'return { vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.api.nvim_get_mode().mode }',
  expected = { { 'two', 'one', 'three' }, 'i' },
})
equals('<M-S-j> moves the line down in insert mode and stays in insert mode', got, expected)

got, expected = typed({ keys = 'Vj<M-S-j>', read = lines, expected = { 'three', 'one', 'two' } })
equals('<M-S-j> moves the selected lines down in visual mode', got, expected)

got, expected = typed({
  setup = 'vim.o.hlsearch = true',
  keys = '/two<CR><CR>',
  read = 'return { vim.fn.line("."), vim.v.hlsearch }',
  expected = { 2, 0 },
})
equals('<CR> clears the search highlight', got, expected)

got, expected = typed({
  setup = "vim.cmd('vsplit | split')",
  expected_from = [[
    vim.cmd('vertical resize | resize')
    local size = { vim.fn.winwidth(0), vim.fn.winheight(0), 'n' }
    vim.cmd('wincmd =')
    return size
  ]],
  keys = '<Space><Space>',
  read = 'return { vim.fn.winwidth(0), vim.fn.winheight(0), vim.api.nvim_get_mode().mode }',
})
equals('<Space><Space> sizes the window as :vertical resize and :resize do', got, expected)

got, expected = typed({
  setup = "vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'ls' })",
  keys = 'K',
  settle = 800,
  read = 'return { #vim.api.nvim_tabpage_list_wins(0), vim.v.errmsg, vim.api.nvim_get_mode().mode }',
  expected = { 1, '', 'n' },
})
equals('K does nothing', got, expected)

got, expected = typed({
  setup = [[
    vim.fn.setqflist({ { filename = 'first.txt', lnum = 1 }, { filename = 'second.txt', lnum = 1 } })
    vim.cmd('copen')
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
  ]],
  keys = '<CR>',
  read = "return { vim.fn.expand('%:t'), vim.bo.buftype }",
  expected = { 'second.txt', '' },
})
equals('<CR> in the quickfix window opens the entry under the cursor', got, expected)

report.finish()
