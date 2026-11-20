-- Run: nvim --headless -c 'luafile tests/config_translation_test.lua'
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

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

-- Starts a child Neovim with this config. It returns when VeryLazy has run, as in an editor where a user types.
local function start_editor()
  local socket = vim.fn.tempname()
  local job = vim.fn.jobstart({ vim.v.progpath, '--headless', '--listen', socket })
  assert(vim.wait(5000, function() return vim.uv.fs_stat(socket) ~= nil end), 'the child Neovim opened no socket')
  local editor = vim.fn.sockconnect('pipe', socket, { rpc = true })
  assert(
    vim.wait(5000, function() return vim.rpcrequest(editor, 'nvim_get_vvar', 'vim_did_enter') == 1 end),
    'the child Neovim did not reach VimEnter'
  )
  -- A headless Neovim never fires UIEnter, and lazy.nvim fires VeryLazy only after it. Fire it by hand.
  vim.rpcrequest(editor, 'nvim_exec_lua', [[
    vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })
    vim.schedule(function() vim.schedule(function() vim.g.test_started = true end) end)
  ]], {})
  assert(
    vim.wait(5000, function() return vim.rpcrequest(editor, 'nvim_exec_lua', 'return vim.g.test_started', {}) == true end),
    'the child Neovim did not run VeryLazy'
  )
  return editor, job
end

-- Types the keys in a new editor and returns the lines of the which-key window. It waits until done
-- accepts the lines. It returns the last lines that it read when the wait ends, or nil without a window.
local function which_key_window(keys, done)
  local editor, job = start_editor()
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

-- The fzf maps stay VimScript. which-key gives them the descriptions that vim-shortcut showed.
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

local spell_bad = vim.api.nvim_get_hl(0, { name = 'SpellBad', link = false })
local orange = 16753920
check(
  'SpellBad keeps the colorscheme colors and adds an orange undercurl',
  spell_bad.undercurl == true and spell_bad.sp == orange and spell_bad.fg ~= nil,
  'expected undercurl, sp ' .. orange .. ' and a colorscheme fg, got ' .. vim.inspect(spell_bad)
)

local spell_cap = vim.api.nvim_get_hl(0, { name = 'SpellCap', link = false })
check(
  'SpellCap keeps the colorscheme colors and draws a dotted underline, not an undercurl',
  spell_cap.underdotted == true and spell_cap.undercurl == nil
    and spell_cap.fg ~= nil and spell_cap.sp == spell_cap.fg
    and spell_cap.cterm ~= nil and spell_cap.cterm.underline == true,
  'expected underdotted, no undercurl, the colorscheme fg as sp and a cterm underline, got '
    .. vim.inspect(spell_cap)
)

report.finish()
