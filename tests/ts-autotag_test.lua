-- Run: tests/run.sh tests/ts-autotag_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

-- Opens a new file with this extension and these lines, puts the cursor at { row, col }, types the keys, and returns
-- the lines.
local function lines_after_keys(extension, lines, cursor, keys)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(vim.fn.tempname() .. extension))
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, cursor)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'mx', false)
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

-- After nvim_feedkeys, the next message starts without a newline. So feed all keys first, and report the checks after.
local closed_html = lines_after_keys('.html', { '' }, { 1, 0 }, 'i<div>x')
local closed_erb = lines_after_keys('.html.erb', { '' }, { 1, 0 }, 'i<div>x')
local renamed = lines_after_keys('.html', { '<div></div>' }, { 1, 1 }, 'ciwspan<Esc>')

equals('typing an open tag in html adds its closing tag, with the cursor between them', closed_html, { '<div>x</div>' })
equals('typing an open tag in html.erb adds its closing tag, with the cursor between them', closed_erb, { '<div>x</div>' })
equals('renaming an open tag in html renames its closing tag', renamed, { '<span></span>' })

report.finish()
