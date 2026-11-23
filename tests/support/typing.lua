local M = {}

-- Opens the file at path with these lines, and puts the cursor at { row, col }, by default at the start of the buffer.
function M.open(path, lines, cursor)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  vim.api.nvim_win_set_cursor(0, cursor or { 1, 0 })
end

-- Types the keys as a user does, with maps, and returns when Neovim has run them.
function M.type(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), 'mx', false)
end

-- Opens a new file with this extension and these lines, types the keys, and returns the lines.
function M.lines_after_keys(extension, lines, keys, cursor)
  M.open(vim.fn.tempname() .. extension, lines, cursor)
  M.type(keys)
  return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

return M
