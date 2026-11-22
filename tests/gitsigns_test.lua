-- Run: tests/run.sh tests/gitsigns_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local equals = report.equals

local indexed = { 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten' }
local edited = { 'one', 'two', 'THREE', 'four', 'five', 'six', 'seven', 'EIGHT', 'NINE', 'ten' }

-- Lists the lines with a gitsigns sign for a change that is not staged.
local signed_lines = [[
  local lines = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { type = 'sign', details = true })) do
    local group = mark[4].sign_hl_group or ''
    if group:find('^GitSigns') and not group:find('^GitSignsStaged') then
      table.insert(lines, mark[2] + 1)
    end
  end
  table.sort(lines)
  return lines
]]

-- Opens file.txt of a new repo in a child Neovim and waits for the git signs.
-- It returns a function that runs Lua in the child, and the child job.
local function open_edited_file()
  local dir = git_repo.new(indexed, edited)
  local editor, job = child.start({ cwd = dir, files = { 'file.txt' } })
  local function run(code, ...)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
  end
  vim.wait(5000, function() return #run(signed_lines) > 0 end)
  return run, job, dir, editor
end

-- Lists the lines of file.txt in the index of the repo in dir.
local function index_of(dir)
  local shown = vim.system({ 'git', '-C', dir, 'show', ':file.txt' }, { stdin = false }):wait().stdout
  return vim.split(shown, '\n', { trimempty = true })
end

-- Opens the edited file, runs the Lua of case.setup if any, puts the cursor on case.line and types case.keys.
-- Then it waits until case.read(run, dir) returns case.expected, and returns the last value that it read.
local function after_keys(case)
  local run, job, dir, editor = open_edited_file()
  if case.setup then
    run(case.setup)
  end
  run('vim.api.nvim_win_set_cursor(0, { ..., 0 })', case.line)
  run("vim.api.nvim_feedkeys(vim.keycode(...), 'mt', false)", case.keys)
  local got
  vim.wait(3000, function()
    -- Without a map, the keys can end in a command that waits for a character, such as gr.
    -- The child then holds each request until a key comes, so press Escape to free it.
    if vim.rpcrequest(editor, 'nvim_get_mode').blocking then
      vim.rpcrequest(editor, 'nvim_input', '<Esc>')
      return false
    end
    got = case.read(run, dir)
    return vim.deep_equal(got, case.expected)
  end)
  vim.fn.jobstop(job)
  return got
end

local function read_index(_, dir)
  return index_of(dir)
end

local function with_line(lines, number, text)
  local copy = vim.deepcopy(lines)
  copy[number] = text
  return copy
end

local run, job = open_edited_file()
equals('opening an edited file shows a git sign on each changed line', run(signed_lines), { 3, 8, 9 })
local undescribed = [[
  local keymaps = dofile(...)
  local missing = keymaps.undescribed({ ']c', '[c', '<leader>gp', '<leader>gb' }, { 'n' })
  vim.list_extend(missing, keymaps.undescribed({ '<leader>gs', '<leader>gr' }, { 'n', 'x' }))
  return vim.list_extend(missing, keymaps.undescribed({ 'ih' }, { 'o', 'x' }))
]]
equals('every gitsigns map has a description for which-key', run(undescribed, tests_dir .. '/support/keymaps.lua'), {})
vim.fn.jobstop(job)

local staged = with_line(indexed, 3, 'THREE')
equals(
  '<leader>gs stages the hunk under the cursor',
  after_keys({ line = 3, keys = '<leader>gs', expected = staged, read = read_index }),
  staged
)

local selection_staged = with_line(indexed, 9, 'NINE')
equals(
  '<leader>gs in visual mode stages only the selected lines of a hunk',
  after_keys({ line = 9, keys = 'V<leader>gs', expected = selection_staged, read = read_index }),
  selection_staged
)

local function read_buffer(run)
  return run('return vim.api.nvim_buf_get_lines(0, 0, -1, false)')
end

local reset = with_line(edited, 3, 'three')
equals(
  '<leader>gr resets the hunk under the cursor',
  after_keys({ line = 3, keys = '<leader>gr', expected = reset, read = read_buffer }),
  reset
)

local selection_reset = with_line(edited, 9, 'nine')
equals(
  '<leader>gr in visual mode resets only the selected lines of a hunk',
  after_keys({ line = 9, keys = 'V<leader>gr', expected = selection_reset, read = read_buffer }),
  selection_reset
)

local function float_shows(text)
  return function(run)
    return run([[
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_config(win).relative ~= '' then
          local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
          if table.concat(lines, '\n'):find(..., 1, true) then
            return true
          end
        end
      end
      return false
    ]], text)
  end
end

equals(
  '<leader>gp shows the hunk under the cursor in a float',
  after_keys({ line = 3, keys = '<leader>gp', expected = true, read = float_shows('THREE') }),
  true
)

local function read_line(run)
  return run([[return vim.fn.line('.')]])
end

equals(
  ']c moves to the start of the next hunk',
  after_keys({ line = 1, keys = ']c', expected = 3, read = read_line }),
  3
)
equals(
  '[c moves to the start of the previous hunk',
  after_keys({ line = 7, keys = '[c', expected = 3, read = read_line }),
  3
)

-- The other buffer differs from file.txt only on lines 5 and 7, so a jump by diff goes to line 5 and a jump by hunk to line 3.
local diff_setup = [[
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  lines[5] = 'FIVE'
  lines[7] = 'SEVEN'
  vim.cmd('vertical new | setlocal buftype=nofile')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd('diffthis | wincmd p | diffthis')
]]
equals(
  ']c in a diff window moves to the next diff change, not to the next hunk',
  after_keys({ setup = diff_setup, line = 1, keys = ']c', expected = 5, read = read_line }),
  5
)
equals(
  ']c with a count in a diff window moves that many diff changes',
  after_keys({ setup = diff_setup, line = 1, keys = '2]c', expected = 7, read = read_line }),
  7
)

local without_hunk = { 'one', 'two', 'THREE', 'four', 'five', 'six', 'seven', 'ten' }
equals(
  'dih deletes the lines of the hunk under the cursor',
  after_keys({ line = 9, keys = 'dih', expected = without_hunk, read = read_buffer }),
  without_hunk
)
equals(
  'ih in visual mode selects the lines of the hunk under the cursor',
  after_keys({ line = 9, keys = 'vihd', expected = without_hunk, read = read_buffer }),
  without_hunk
)

report.finish()
