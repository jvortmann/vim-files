local M = {}

-- Lists each map of lhs_list that is missing or has no description, in the modes n, x, s and o. An entry reads "<mode> <lhs>".
function M.undescribed(lhs_list)
  local missing = {}
  for _, lhs in ipairs(lhs_list) do
    for _, mode in ipairs({ 'n', 'x', 's', 'o' }) do
      local desc = vim.fn.maparg(lhs, mode, false, true).desc
      if type(desc) ~= 'string' or desc == '' then
        table.insert(missing, mode .. ' ' .. lhs)
      end
    end
  end
  return missing
end

return M
