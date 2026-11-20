-- Run: nvim -i NONE --headless -c 'luafile tests/config_translation_test.lua'
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local child = dofile(tests_dir .. '/support/editor.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')

-- which-key draws its title and its list in separate windows, so this reads every window of filetype wk.
local read_which_key_window = [[
  local lines
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == 'wk' then
      lines = vim.list_extend(lines or {}, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    end
  end
  return lines
]]

-- Types the keys in a new editor and returns the lines of the which-key window. It waits until done
-- accepts the lines. It returns the last lines that it read when the wait ends, or nil without a window.
local function which_key_window(keys, done)
  local editor, job = child.start()
  vim.rpcrequest(editor, 'nvim_input', keys)
  local lines
  vim.wait(3000, function()
    lines = vim.rpcrequest(editor, 'nvim_exec_lua', read_which_key_window, {})
    if lines == vim.NIL then
      lines = nil
    end
    return lines ~= nil and done(lines)
  end)
  vim.fn.jobstop(job)
  return lines
end

for mode, keys in vim.spairs({ n = '\\h', x = 'v\\h' }) do
  local lines = which_key_window(keys, function(got) return #got > 0 end)
  check(
    'leader h opens the which-key window in mode ' .. mode,
    lines ~= nil and #lines > 0,
    'no which-key window opened, got ' .. vim.inspect(lines)
  )
end

local function shows_name(lines, name)
  for _, line in ipairs(lines) do
    if line:find(name .. '  ', 1, true) or vim.endswith(vim.trim(line), name) then
      return true
    end
  end
  return false
end

-- The fzf-lua keys keep the names that vim-shortcut showed, and which-key shows them.
-- Each key is the prefix that the test types after <leader>h. Its names are the ones the window shows.
local fzf_names = {
  ['\\'] = { 'Find files (fallback)', 'Find open buffers (fallback)' },
  ['\\f'] = {
    'Find files', 'Find lines in current buffer', 'Find marks', 'Find open buffers',
    'Find tags on current buffer', 'Find files history',
  },
  ['\\fl'] = { 'Find lines in open buffers' },
  ['\\ft'] = { 'Find tags' },
}
local unnamed = {}
for prefix, names in vim.spairs(fzf_names) do
  local lines = which_key_window('\\h' .. prefix, function(got)
    return shows_name(got, names[1])
  end) or {}
  for _, name in ipairs(names) do
    if not shows_name(lines, name) then
      table.insert(unnamed, prefix .. ': ' .. name)
    end
  end
end
report.equals('which-key shows the name of each fzf map', unnamed, {})

-- Opens a float in Neovim inside a tmux pane. It returns the background of the float text as the pane
-- draws it, an "r;g;b" string, or nil when no float shows.
local function float_background_on_screen()
  local open_float = [[
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'float text' })
    vim.api.nvim_open_win(buf, false, { relative = 'editor', row = 2, col = 2, width = 20, height = 3, style = 'minimal' })
  ]]
  local pane = screen.start({ width = 80, height = 24, args = { '-c', 'lua ' .. open_float } })
  local background
  vim.wait(5000, function()
    local before = table.concat(pane.rows(true), '\n'):match('([^\n]*)float text')
    for color in (before or ''):gmatch('48;2;(%d+;%d+;%d+)m') do
      background = color
    end
    return background ~= nil
  end)
  pane.stop()
  return background
end

report.equals('a float draws on the solarized base02 background', float_background_on_screen(), '7;54;66')

-- Checks the colors of the git signs. Each check name ends with the moment in `when`.
local function check_git_sign_colors(when)
  for group, color in vim.spairs({ GitSignsAdd = '#859900', GitSignsChange = '#b58900', GitSignsDelete = '#dc322f' }) do
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    report.equals(group .. ' draws in ' .. color .. ' ' .. when, fg and ('#%06x'):format(fg), color)
  end
end

-- Checks the colors that the config sets on top of the colorscheme. Each check name ends with the moment in `when`.
local function check_colors(when)
  local spell_bad = vim.api.nvim_get_hl(0, { name = 'SpellBad', link = false })
  local orange = 16753920
  check(
    'SpellBad keeps the colorscheme colors and adds an orange undercurl ' .. when,
    spell_bad.undercurl == true and spell_bad.sp == orange and spell_bad.fg ~= nil,
    'expected undercurl, sp ' .. orange .. ' and a colorscheme fg, got ' .. vim.inspect(spell_bad)
  )

  local spell_cap = vim.api.nvim_get_hl(0, { name = 'SpellCap', link = false })
  check(
    'SpellCap keeps the colorscheme colors and draws a dotted underline, not an undercurl ' .. when,
    spell_cap.underdotted == true and spell_cap.undercurl == nil
      and spell_cap.fg ~= nil and spell_cap.sp ~= nil
      and spell_cap.cterm ~= nil and spell_cap.cterm.underline == true,
    'expected underdotted, no undercurl, a colorscheme fg and sp and a cterm underline, got '
      .. vim.inspect(spell_cap)
  )

  report.equals('floats take the popup menu colors ' .. when, vim.api.nvim_get_hl(0, { name = 'NormalFloat' }), { link = 'Pmenu' })
  check_git_sign_colors(when)
end

check_colors('at startup')
vim.cmd('colorscheme solarized8')
check_colors('after the colorscheme loads again')
vim.o.background = 'light'
check_colors('after the background changes to light')
vim.o.background = 'dark'
check_colors('after the background changes back to dark')
vim.cmd('colorscheme default')
check_git_sign_colors('after another colorscheme loads')

report.finish()
