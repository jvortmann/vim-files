-- Run: nvim -i NONE --headless -c 'luafile tests/lualine_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')

-- After nvim_feedkeys, the next message starts without a newline. So run every check first, then report them all.
local results = {}
local function check(name, ok, detail)
  table.insert(results, function() report.check(name, ok, detail) end)
end
local function equals(name, got, expected)
  table.insert(results, function() report.equals(name, got, expected) end)
end

local folder = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(folder .. '/sub', 'p')
vim.cmd.cd(folder)

local function open(name, lines, options)
  vim.cmd('silent! %bwipeout!')
  vim.fn.writefile(lines or {}, folder .. '/' .. name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(name))
  for option, value in pairs(options or {}) do
    vim.opt_local[option] = value
  end
end

-- Forces a refresh first, so the result is never older than the last change.
local function statusline(win)
  win = win or vim.api.nvim_get_current_win()
  require('lualine').refresh({ scope = 'all', place = { 'statusline' }, force = true })
  return vim.api.nvim_eval_statusline(vim.wo[win].statusline, { winid = win, highlights = true })
end

local function shows(name, text)
  local got = statusline().str
  check(name, got:find(text, 1, true) ~= nil, 'expected ' .. vim.inspect(text) .. ' in ' .. vim.inspect(got))
end

open('sub/file.txt', { 'one two' })
local line = statusline().str
check('the statusline shows no separator or icon glyph', not line:find('[\128-\255]'), 'got ' .. vim.inspect(line))
equals('each window has its own statusline, and the mode shows only there', { vim.o.laststatus, vim.o.showmode }, { 2, false })

local function mode_part()
  local first = statusline().highlights[1]
  return { vim.trim(statusline().str):match('^%S+'), first.group, vim.api.nvim_get_hl(0, { name = first.group }).bg }
end
local normal = mode_part()
vim.api.nvim_feedkeys('V', 'x!', false)
local visual = mode_part()
vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'x', false)
equals(
  'the mode name shows in the color of the mode',
  { normal[1], normal[2], visual[1], visual[2], normal[3] ~= visual[3] },
  { 'NORMAL', 'lualine_a_normal', 'V-LINE', 'lualine_a_visual', true }
)

open('sub/file.txt', { 'one two' }, { spell = true, spelllang = 'en_us,en_gb' })
shows('the statusline shows the spell languages when spell is on', 'SPELL [EN_US/EN_GB]')

open('sub/file.txt', { 'one two' }, { modified = true })
shows('the statusline shows the path from the working folder and the modified marker', 'sub/file.txt [+]')

open('sub/file.txt', { 'one two' }, { readonly = true })
shows('the statusline shows the readonly marker', 'sub/file.txt [RO]')

open('notes.md', { 'one two', 'three' })
shows('the statusline shows the file type', 'markdown')
shows('the statusline shows the word count of a text file', '3 words')
vim.api.nvim_feedkeys('ggV', 'x!', false)
shows('in visual mode, the statusline shows the word count of the selection', '2 words')
vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'x', false)

open('code.lua', { 'local one = 1' })
local code_line = statusline().str
check('the statusline shows no word count for a code file', not code_line:find('words', 1, true), 'got ' .. vim.inspect(code_line))

open('sub/file.txt', { 'one', 'two', 'three', 'four' })
shows('the statusline shows how far the cursor is in the file, in percent, and the count of lines', '25%:4')
vim.api.nvim_win_set_cursor(0, { 2, 2 })
shows('the statusline shows the line and the column', ' 2:3 ')

local namespace = vim.api.nvim_create_namespace('lualine_test')
vim.diagnostic.set(namespace, 0, vim.tbl_map(function(severity)
  return { lnum = 0, col = 0, severity = severity, message = 'problem' }
end, { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN, vim.diagnostic.severity.WARN, vim.diagnostic.severity.INFO }))
local diagnostics_line = statusline().str
equals(
  'the statusline shows the count of errors and warnings, and no other diagnostic',
  { diagnostics_line:find('E:1 W:2', 1, true) ~= nil, diagnostics_line:find('I:', 1, true) ~= nil },
  { true, false }
)

vim.fn.setqflist({}, ' ', { title = 'search for two', items = { { filename = 'sub/file.txt', lnum = 2, text = 'two' } } })
vim.cmd('copen')
shows('the quickfix window shows the title of the list', 'search for two')
vim.cmd('cclose')

open('sub/file.txt', { 'one' })
local plain_line = statusline().str
check(
  'the statusline shows no encoding or file format for utf-8 and unix',
  not plain_line:find('utf-8', 1, true) and not plain_line:find('unix', 1, true),
  'got ' .. vim.inspect(plain_line)
)

open('sub/file.txt', { 'one' }, { fileencoding = 'latin1', fileformat = 'dos' })
shows('the statusline shows any other encoding and file format', 'latin1[dos]')

open('sub/file.txt', { 'one' }, { endofline = false, fixendofline = false })
shows('the statusline shows a missing newline at the end of the file', 'utf-8[!EOL][unix]')

open('sub/file.txt', { 'one' }, { endofline = false, fixendofline = true })
local fixed_line = statusline().str
check(
  'the statusline shows no missing newline when a write adds it',
  not fixed_line:find('EOL', 1, true),
  'got ' .. vim.inspect(fixed_line)
)

vim.cmd('enew')
local new_line = statusline().str
check('the statusline of a new buffer shows no file format', not new_line:find('unix', 1, true), 'got ' .. vim.inspect(new_line))
check(
  'the statusline of an empty buffer shows numbers for the position',
  new_line:find('100%:1', 1, true) ~= nil and new_line:find(' 0:1 ', 1, true) ~= nil,
  'got ' .. vim.inspect(new_line)
)

open('sub/file.txt', { 'two', 'one two' })
vim.fn.setreg('/', 'two')
vim.o.hlsearch = true
vim.v.hlsearch = 1
shows('the statusline shows the match under the cursor and the count of matches', '[1/2]')
vim.v.hlsearch = 0

open('sub/file.txt', { 'one', 'two ', 'three ' })
shows('the statusline shows the first line with trailing whitespace', '[2]trailing')

open('sub/file.txt', { 'one', '\ttwo', '\t  three', '  \tfour' })
shows('the statusline shows the first line that indents with tabs and spaces', '[3]mixed-indent')

open('sub/file.txt', { 'one', 'two ', 'three' })
statusline()
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two', 'three ' })
shows('the whitespace warning keeps its line until an event updates it', '[2]trailing')
vim.api.nvim_feedkeys('i' .. vim.keycode('<Esc>'), 'x', false)
shows('leaving insert mode updates the whitespace warning', '[3]trailing')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one ', 'two', 'three' })
vim.cmd('silent write')
shows('a write updates the whitespace warning', '[1]trailing')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'one', 'two ', 'three' })
vim.cmd('silent edit code.lua')
vim.cmd('silent buffer #')
shows('entering the buffer updates the whitespace warning', '[2]trailing')

open('sub/file.txt', { 'one ' }, { modifiable = false })
local locked_line = statusline().str
check('a buffer that cannot change shows no whitespace warning', not locked_line:find('trailing', 1, true), 'got ' .. vim.inspect(locked_line))

open('sub/file.txt', { 'one', 'two', 'three', 'four' })
vim.api.nvim_win_set_cursor(0, { 2, 2 })
local inactive_win = vim.api.nvim_get_current_win()
vim.cmd('silent split code.lua')
local inactive = statusline(inactive_win)
equals(
  'an inactive window shows the file name and the position, in one color',
  {
    vim.trim(inactive.str):gsub('%s+', ' '),
    #vim.tbl_filter(function(part) return part.group ~= inactive.highlights[1].group end, inactive.highlights),
  },
  { 'sub/file.txt 50%:4 2:3', 0 }
)
vim.cmd('only')

-- Returns the colors of the mode and of the middle in normal mode, and v:errmsg.
local function normal_mode_colors()
  statusline()
  local mode = vim.api.nvim_get_hl(0, { name = 'lualine_a_normal' })
  local middle = vim.api.nvim_get_hl(0, { name = 'lualine_c_normal' })
  return vim.tbl_map(function(color) return ('#%06x'):format(color) end, { mode.fg, mode.bg, middle.bg }), vim.v.errmsg
end

local function theme_colors(name)
  local normal = require('lualine.themes.' .. name).normal
  return { normal.a.fg, normal.a.bg, normal.c.bg }
end

vim.v.errmsg = ''
equals(
  'with solarized8 and a dark background, the statusline takes the colors of the solarized dark theme',
  { normal_mode_colors() },
  { theme_colors('solarized_dark'), '' }
)
vim.o.background = 'light'
equals(
  'a switch to a light background gives the statusline the colors of the solarized light theme',
  { normal_mode_colors() },
  { theme_colors('solarized_light'), '' }
)
vim.cmd('colorscheme catppuccin')
local other_colors, other_error = normal_mode_colors()
equals(
  'another colorscheme gives the statusline other colors, with no error',
  {
    vim.deep_equal(other_colors, theme_colors('solarized_light')),
    vim.deep_equal(other_colors, theme_colors('solarized_dark')),
    other_error,
  },
  { false, false, '' }
)

for _, result in ipairs(results) do
  result()
end
report.finish()
