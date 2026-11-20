local M = {}

-- Lists each lhs of lhs_list that has no map or no description in a mode. The modes default to n, x, s and o.
-- An entry reads "<mode> <lhs>".
function M.undescribed(lhs_list, modes)
  local missing = {}
  for _, lhs in ipairs(lhs_list) do
    for _, mode in ipairs(modes or { 'n', 'x', 's', 'o' }) do
      local desc = vim.fn.maparg(lhs, mode, false, true).desc
      if type(desc) ~= 'string' or desc == '' then
        table.insert(missing, mode .. ' ' .. lhs)
      end
    end
  end
  return missing
end

return M
