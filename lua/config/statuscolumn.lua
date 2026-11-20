local M = {}

local column = "%!v:lua.require'config.statuscolumn'.render()"
local sign, update

function M.setup()
  local group = vim.api.nvim_create_augroup('config_statuscolumn', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinNew' }, {
    group = group,
    callback = function(args) update(args.buf) end,
  })
  vim.api.nvim_create_autocmd('OptionSet', {
    group = group,
    pattern = 'buftype',
    callback = function() update(vim.api.nvim_get_current_buf()) end,
  })
end

function M.render()
  if vim.v.virtnum ~= 0 then
    return ''
  end
  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local cell = sign(buf, vim.v.lnum - 1)
  if not vim.wo[win].number then
    return cell .. ' '
  end
  local width = math.max(vim.wo[win].numberwidth, #tostring(vim.api.nvim_buf_line_count(buf)) + 1)
  return cell .. string.format('%' .. (width - 1) .. 'd ', vim.v.lnum)
end

-- Gives each window of the buffer the column when the buffer holds a file and the window is not a float.
-- It takes the column away from the other windows of the buffer.
function update(buf)
  local file = vim.bo[buf].buftype == ''
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if file and vim.api.nvim_win_get_config(win).relative == '' then
      vim.api.nvim_set_option_value('statuscolumn', column, { scope = 'local', win = win })
      vim.api.nvim_set_option_value('signcolumn', 'no', { scope = 'local', win = win })
    elseif vim.wo[win].statuscolumn == column then
      vim.api.nvim_set_option_value('statuscolumn', '', { scope = 'local', win = win })
      vim.api.nvim_set_option_value('signcolumn', vim.go.signcolumn, { scope = 'local', win = win })
    end
  end
end

-- Returns the first character of the sign of the highest priority on the row, with its highlight, or a blank cell.
function sign(buf, row)
  local details
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, { type = 'sign', details = true })) do
    if mark[4].sign_text and (not details or mark[4].priority > details.priority) then
      details = mark[4]
    end
  end
  if not details then
    return ' '
  end
  local character = details.sign_text:match('[^%s\128-\191][\128-\191]*') or ' '
  return '%#' .. (details.sign_hl_group or 'SignColumn') .. '#' .. character .. '%*'
end

return M
