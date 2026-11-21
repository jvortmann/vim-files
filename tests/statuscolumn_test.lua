-- Run: nvim -i NONE --headless -c 'luafile tests/statuscolumn_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')
local git_repo = dofile(tests_dir .. '/support/git_repo.lua')
local equals = report.equals

-- Writes the lines to file.txt in a new folder outside git, and returns the folder.
local function new_folder(lines)
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, 'p')
  vim.fn.writefile(lines, dir .. '/file.txt')
  return dir
end

-- Waits until the first row of the pane that contains text equals expected.
-- It returns that row as it last read it, or nil when no row contains text.
local function row_with(pane, text, expected)
  local found
  vim.wait(5000, function()
    found = nil
    for _, row in ipairs(pane.rows()) do
      if row:find(text, 1, true) then
        found = row
        break
      end
    end
    return found == expected
  end)
  return found
end

-- Waits until a row of the pane starts with text, and returns the start of the first row that contains text.
local function start_of_row_with(pane, text)
  local width = vim.api.nvim_strwidth(text)
  local found
  vim.wait(5000, function()
    found = nil
    for _, row in ipairs(pane.rows()) do
      local at = row:find(text, 1, true)
      if at then
        found = vim.fn.strcharpart(row, 0, vim.fn.strchars(row:sub(1, at - 1)) + width)
        break
      end
    end
    return found == text
  end)
  return found
end

-- Returns the foreground color, as "r;g;b", that the pane draws for cells on the first row that contains text.
local function cell_color(pane, text, cells)
  for _, row in ipairs(pane.rows(true)) do
    if row:find(text, 1, true) then
      local color
      for found in (row:match('^(.*)' .. vim.pesc(cells)) or ''):gmatch('38;2;(%d+;%d+;%d+)m') do
        color = found
      end
      return color
    end
  end
end

-- Returns the foreground color of the highlight group in the Neovim of the pane, as "r;g;b".
local function group_color(pane, group)
  local rgb = pane.run('return vim.api.nvim_get_hl(0, { name = ..., link = false }).fg', group)
  return ('%d;%d;%d'):format(bit.rshift(rgb, 16), bit.band(bit.rshift(rgb, 8), 255), bit.band(rgb, 255))
end

local pane = screen.start({ cwd = new_folder({ 'one', 'two', string.rep('w', 50) }), args = { 'file.txt' } })
equals('a line with no sign has one blank cell before its number', row_with(pane, 'two', '   2 two'), '   2 two')
-- The pane is 40 cells wide, so the text area takes 35 of the 50 cells of line 3, and 'showbreak' starts the rest.
local continued = '     ↪  ' .. string.rep('w', 15)
equals('the rest of a wrapped line starts at the column of the text above', row_with(pane, '↪', continued), continued)
-- A diagnostic sign has two cells, such as 'x '.
local place_sign = [[
  local row, text, priority = ...
  local namespace = vim.api.nvim_create_namespace('statuscolumn_test')
  vim.api.nvim_buf_set_extmark(0, namespace, row - 1, 0, { sign_text = text, sign_hl_group = 'ErrorMsg', priority = priority })
]]
pane.run(place_sign, 1, 'x ', 30)
equals('a sign of two cells shows its first character', row_with(pane, 'one', 'x  1 one'), 'x  1 one')
pane.run(place_sign, 2, ' y', 30)
equals('a sign that starts with a blank shows its first visible character', row_with(pane, 'two', 'y  2 two'), 'y  2 two')
-- Lines 1 and 2 now have a sign, and the cursor is on line 1.
equals('the number of the cursor line keeps the CursorLineNr color', cell_color(pane, 'one', '1 '), group_color(pane, 'CursorLineNr'))
equals('the number of another line keeps the LineNr color', cell_color(pane, 'two', '2 '), group_color(pane, 'LineNr'))
pane.run([[vim.api.nvim_buf_set_extmark(0, vim.api.nvim_create_namespace('statuscolumn_test'), 1, 0, { number_hl_group = 'ErrorMsg', priority = 50 })]])
equals('a sign mark with no text does not hide the sign of the line', row_with(pane, 'two', 'y  2 two'), 'y  2 two')
pane.run([[vim.api.nvim_buf_set_extmark(0, vim.api.nvim_create_namespace('statuscolumn_test'), 0, 0, { sign_text = 'z', priority = 60 })]])
equals('a sign with no highlight group shows its character', row_with(pane, 'one', 'z  1 one'), 'z  1 one')
pane.run(place_sign, 3, ' ', 30)
local blank_sign = '   3 ' .. string.rep('w', 35)
equals('a sign of blanks leaves the cell blank', row_with(pane, '3 w', blank_sign), blank_sign)
pane.run([[vim.wo.number = false]])
equals('a window with no line numbers shows the sign cell and a blank before the text', row_with(pane, 'one', 'z one'), 'z one')
pane.stop()

-- Sets diagnostics on the current buffer of the pane. Each argument is a line number and a severity.
local set_diagnostics = [=[
  local diagnostics = {}
  for _, entry in ipairs({ ... }) do
    table.insert(diagnostics, { lnum = entry[1] - 1, col = 0, severity = vim.diagnostic.severity[entry[2]], message = entry[2] })
  end
  vim.diagnostic.set(vim.api.nvim_create_namespace('statuscolumn_test_diagnostics'), 0, diagnostics)
]=]
pane = screen.start({ cwd = new_folder({ 'one', 'two', 'three', 'four' }), args = { 'file.txt' } })
pane.run(set_diagnostics, { 1, 'ERROR' }, { 2, 'WARN' }, { 3, 'INFO' }, { 4, 'HINT' })
equals(
  'a diagnostic shows x, !, or i in the sign cell, by its severity',
  { row_with(pane, 'one', 'x  1 one'), row_with(pane, 'two', '!  2 two'), row_with(pane, 'three', 'i  3 three'), row_with(pane, 'four', 'i  4 four') },
  { 'x  1 one', '!  2 two', 'i  3 three', 'i  4 four' }
)
equals(
  'a diagnostic sign takes the color of the matching diff group',
  -- The underlines split the text of each line with color codes, so the test finds each row by its number.
  { cell_color(pane, '1 ', 'x'), cell_color(pane, '2 ', '!'), cell_color(pane, '3 ', 'i'), cell_color(pane, '4 ', 'i') },
  { group_color(pane, 'DiffDelete'), group_color(pane, 'DiffChange'), group_color(pane, 'DiffText'), group_color(pane, 'DiffText') }
)
pane.run(set_diagnostics, { 1, 'ERROR' }, { 1, 'WARN' })
equals('a line with a warning and an error shows x', row_with(pane, 'one', 'x  1 one'), 'x  1 one')
pane.stop()

pane = screen.start({ cwd = git_repo.new({ 'one', 'two', 'three', 'four' }, { 'one', 'two', 'THREE', 'four', 'five' }), args = { 'file.txt' } })
equals('a changed line shows its git sign right before its number', row_with(pane, 'THREE', '┃  3 THREE'), '┃  3 THREE')
equals('an added line shows a bar on the left edge of the sign cell', row_with(pane, 'five', '▏  5 five'), '▏  5 five')
equals('the bar of an added line is solarized green', cell_color(pane, 'five', '▏'), '133;153;0')
equals('the bar of a changed line is solarized yellow', cell_color(pane, 'THREE', '┃'), '181;137;0')
-- The repo has no commit, so gitsigns shows each line of the index as a staged added line.
equals('a staged added line shows the same bar', row_with(pane, 'one', '▏  1 one'), '▏  1 one')
pane.run(place_sign, 3, 'x ', 30)
equals('a line with two signs shows the sign of the higher priority', row_with(pane, 'THREE', 'x  3 THREE'), 'x  3 THREE')
pane.run(set_diagnostics, { 5, 'HINT' })
equals('a diagnostic on an added line shows instead of the git sign', row_with(pane, 'five', 'i  5 five'), 'i  5 five')
pane.stop()

-- Edits file.txt in one window, runs the command, and keeps only the window that it opened.
local open_alone = [[
  vim.cmd('silent! only')
  vim.cmd.edit('file.txt')
  local file = vim.api.nvim_get_current_buf()
  vim.cmd(...)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) ~= file then
      vim.api.nvim_set_current_win(win)
    end
  end
  vim.cmd('only')
]]
local folder = new_folder({ 'local function one() end' })
pane = screen.start({ cwd = folder, args = { 'file.txt' } })
pane.run(open_alone, 'help')
equals('a help window shows no number and no sign cell', start_of_row_with(pane, 'help.txt'), 'help.txt')
pane.run(open_alone, 'NvimTreeToggle')
-- The first row of nvim-tree starts with the path of the folder.
local root = folder:sub(1, 10)
equals('an nvim-tree window shows no number and no sign cell', start_of_row_with(pane, root), root)
pane.run(open_alone, 'setfiletype lua | Tagbar')
equals('a tagbar window shows no number and no sign cell', start_of_row_with(pane, '" Press <F1>'), '" Press <F1>')
pane.run(open_alone, 'terminal echo terminal-output')
equals('a terminal window shows no number and no sign cell', start_of_row_with(pane, 'terminal-output'), 'terminal-output')
pane.run([[
  vim.cmd('silent! only')
  vim.cmd.edit('file.txt')
  vim.api.nvim_open_win(0, true, { relative = 'editor', row = 3, col = 10, width = 20, height = 1 })
]])
local float_cells
vim.wait(5000, function()
  -- The float starts at row 4 and column 11 of the pane.
  float_cells = pane.rows()[4]:sub(11)
  return float_cells == '  1 local function o'
end)
equals('a float of the file keeps the number column of Neovim', float_cells, '  1 local function o')
pane.stop()

report.finish()
