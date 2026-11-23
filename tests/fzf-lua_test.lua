-- Run: tests/run.sh tests/fzf-lua_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')
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

local pane = screen.start({
  width = 120,
  height = 30,
  cwd = new_folder({ ['main.txt'] = { 'one' }, ['other.txt'] = { 'alpha' } }),
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
-- ctrl-v ends the picker with an action, so fzf writes the query to its history.
type_keys('<C-v>')
assert(vim.wait(5000, function()
  local split = pane.run([[return { #vim.api.nvim_tabpage_list_wins(0), vim.fn.winlayout()[1], vim.fn.expand('%:t') }]])
  return vim.deep_equal(split, { 2, 'row', 'other.txt' })
end), 'ctrl-v did not open other.txt from the files picker')
equals(
  'the files picker keeps its query in the files history of g:fzf_history_dir',
  vim.fn.filereadable(history_dir .. '/files') == 1 and vim.fn.readfile(history_dir .. '/files') or {},
  { 'otx' }
)

pane.stop()
report.finish()
