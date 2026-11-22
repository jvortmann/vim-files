-- Run: tests/run.sh tests/fzf-lua_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')
local equals = report.equals

local leader = vim.g.mapleader or '\\'

-- Writes the files, a map of names to lines, into a new folder, and returns the folder.
local function new_folder(files)
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, 'p')
  for name, lines in pairs(files) do
    vim.fn.writefile(lines, dir .. '/' .. name)
  end
  return dir
end

-- Returns the name of the fzf-lua picker that waits for input, or nil.
local open_picker = [[
  if _G.FzfLua and FzfLua.utils.fzf_winobj() and vim.api.nvim_get_mode().mode == 't' then
    return FzfLua.get_info().cmd
  end
]]

-- Each find key after the leader, and the fzf-lua picker that it opens.
local pickers = {
  { 'ff', 'files' }, { 'f', 'files' }, { 'fl', 'blines' }, { 'fla', 'lines' }, { 'fm', 'marks' },
  { 'fo', 'buffers' }, { 'o', 'buffers' }, { 'ft', 'btags' }, { 'fta', 'tags' }, { 'fh', 'history' },
}
equals('<C-x><C-k> in insert mode is the dictionary completion of Neovim', vim.fn.maparg('<C-x><C-k>', 'i'), '')
equals('fzf keeps its history in the folder of fzf.vim', vim.g.fzf_history_dir, '~/.config/fzf/fzf-history')

local find_keys = { '<leader>fg', '<leader>fw' }
for _, case in ipairs(pickers) do
  table.insert(find_keys, '<leader>' .. case[1])
end
equals('every find key has a description for which-key', keymaps.undescribed(find_keys), {})

-- The tags picker reads the tags file, and the btags picker runs ctags on first.lua.
local tags_folder = new_folder({
  ['first.lua'] = { 'local function one() end' },
  ['second.lua'] = { 'local function two() end' },
  tags = { 'one\tfirst.lua\t/^local function one() end$/;"\tf' },
})
local editor, job = child.start({ cwd = tags_folder, files = { 'first.lua', 'second.lua' } })
-- The child keeps its queries out of the fzf history of the user, and sets a mark for the marks picker.
vim.rpcrequest(editor, 'nvim_exec_lua', [[
  vim.g.fzf_history_dir = ...
  vim.cmd.normal({ 'ma', bang = true })
]], { vim.fn.tempname() })
local opened, expected_pickers = {}, {}
for _, case in ipairs(pickers) do
  local keys, expected = leader .. case[1], case[2]
  expected_pickers[keys] = expected
  vim.rpcrequest(editor, 'nvim_input', keys)
  vim.wait(3000, function()
    opened[keys] = vim.rpcrequest(editor, 'nvim_exec_lua', open_picker, {})
    return opened[keys] == expected
  end)
  vim.rpcrequest(editor, 'nvim_input', '<Esc>')
  vim.wait(3000, function() return vim.rpcrequest(editor, 'nvim_exec_lua', open_picker, {}) == vim.NIL end)
end
vim.fn.jobstop(job)
equals('each find key opens its fzf-lua picker', opened, expected_pickers)

local pane = screen.start({
  width = 120,
  height = 30,
  cwd = new_folder({ ['main.txt'] = { 'needleword here' }, ['other.txt'] = { 'alpha', 'here too', 'needleword' } }),
  args = { 'main.txt' },
})
-- fzf writes each query to its history, so the pane keeps that history out of the history of the user.
local history_dir = vim.fn.tempname()
pane.run('vim.g.fzf_history_dir = ...', history_dir)

local function type_keys(keys)
  pane.run('vim.api.nvim_input(...)', keys)
end

local function picker()
  local name = pane.run(open_picker)
  return name ~= vim.NIL and name or nil
end

-- Types the keys and waits until the picker shows. It returns the name of the picker that shows.
local function open(keys, expected)
  type_keys(keys)
  local got
  vim.wait(5000, function()
    got = picker()
    return got == expected
  end)
  return got
end

local function close()
  type_keys('<Esc>')
  vim.wait(5000, function() return picker() == nil end)
end

-- Waits until the pane lists the grep matches in expected. It returns the last matches that it read, as "file:line".
local function grep_matches(expected)
  local matches
  vim.wait(5000, function()
    matches = {}
    for _, row in ipairs(pane.rows()) do
      for file, line in row:gmatch('(%w+%.txt):(%d+):') do
        table.insert(matches, file .. ':' .. line)
      end
    end
    table.sort(matches)
    return vim.deep_equal(matches, expected)
  end)
  return matches
end

open(leader .. 'fg', 'live_grep')
type_keys('needleword')
equals(
  'leader fg lists each line of the folder that contains the typed text',
  grep_matches({ 'main.txt:1', 'other.txt:3' }),
  { 'main.txt:1', 'other.txt:3' }
)
close()

pane.run([[vim.api.nvim_win_set_cursor(0, { 1, vim.fn.stridx(vim.fn.getline(1), 'here') })]])
open(leader .. 'fw', 'grep_cword')
equals(
  'leader fw lists each line of the folder that contains the word under the cursor',
  grep_matches({ 'main.txt:1', 'other.txt:2' }),
  { 'main.txt:1', 'other.txt:2' }
)
close()

-- Waits until a row of the pane matches the Lua pattern, and returns whether one does.
local function shows(pattern)
  return vim.wait(5000, function()
    for _, row in ipairs(pane.rows()) do
      if row:find(pattern) then
        return true
      end
    end
    return false
  end)
end

-- Returns the background color, as "r;g;b", under the first text on the screen that matches text.
-- It returns nil for the default background, or when no row contains text.
local function background_of(text)
  for _, row in ipairs(pane.rows(true)) do
    local at = row:find(text, 1, true)
    if at then
      local background
      for codes in row:sub(1, at - 1):gmatch('\27%[([%d;]*)m') do
        local params = vim.split(codes, ';')
        local i = 1
        while i <= #params do
          local param = tonumber(params[i]) or 0
          if param == 0 or param == 49 then
            background = nil
          elseif (param == 38 or param == 48) and params[i + 1] == '2' then
            if param == 48 then
              background = table.concat({ params[i + 2], params[i + 3], params[i + 4] }, ';')
            end
            i = i + 4
          elseif (param == 38 or param == 48) and params[i + 1] == '5' then
            if param == 48 then
              background = '5;' .. params[i + 2]
            end
            i = i + 2
          end
          i = i + 1
        end
      end
      return background
    end
  end
end

open(leader .. 'ff', 'files')
-- The query matches only other.txt, so fzf shows 1 of the 2 files, and the preview shows its first line.
type_keys('otx')
shows('1/2')
shows('alpha')
-- The title of the preview names the file on the top border, which is the first row with other.txt.
equals(
  'the list, the preview, the border and the title of a picker draw on the solarized base02 background of a float',
  {
    list = background_of('otx'),
    preview = background_of('alpha'),
    border = background_of('╭'),
    title = background_of('other.txt'),
  },
  { list = '7;54;66', preview = '7;54;66', border = '7;54;66', title = '7;54;66' }
)
local icon = pane.run([[return require('nvim-web-devicons').get_icon('other.txt')]])
-- fzf-lua puts an en space, not a plain space, between the icon and the name.
equals(
  'the files picker shows the devicon of each file before its name',
  shows(vim.pesc(icon) .. '%W+other%.txt'),
  true
)
-- The picker and its preview draw one frame, from the first top-left corner to the last bottom-right corner.
local frame = {}
for number, row in ipairs(pane.rows()) do
  local left, right = row:find('╭', 1, true), row:match('.*()╮')
  if left and not frame.top then
    frame.top = number
    frame.left = vim.fn.strdisplaywidth(row:sub(1, left - 1))
    frame.right = vim.fn.strdisplaywidth(row:sub(1, right - 1))
  end
  if row:find('╰', 1, true) then
    frame.bottom = number
  end
end
-- fzf-lua gives 90% of the 120 columns to the text of the picker and its preview, and draws the 3 border
-- columns outside it. The 17 rows are 60% of the 29 lines above the command line, borders included.
equals(
  'a picker with its preview takes 90% of the columns and 60% of the lines above the command line',
  { width = frame.right - frame.left + 1, height = frame.bottom - frame.top + 1 },
  { width = 108 + 3, height = 17 }
)
type_keys('<C-v>')
local split
vim.wait(5000, function()
  split = pane.run([[return { #vim.api.nvim_tabpage_list_wins(0), vim.fn.winlayout()[1], vim.fn.expand('%:t') }]])
  return vim.deep_equal(split, { 2, 'row', 'other.txt' })
end)
equals('ctrl-v in the files picker opens the file in a vertical split', split, { 2, 'row', 'other.txt' })
equals(
  'the files picker keeps its query in the files history of g:fzf_history_dir',
  vim.fn.filereadable(history_dir .. '/files') == 1 and vim.fn.readfile(history_dir .. '/files') or {},
  { 'otx' }
)

pane.stop()
report.finish()
