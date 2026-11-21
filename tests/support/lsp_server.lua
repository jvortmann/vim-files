local M = {}

-- Returns a cmd for vim.lsp.config or vim.lsp.start that runs a fake server inside this Neovim.
-- The server answers each request with the value of results for its method, or with nil.
function M.cmd(results)
  return function()
    local id = 0
    return {
      request = function(method, _, callback)
        id = id + 1
        callback(nil, results[method])
        return true, id
      end,
      notify = function() return true end,
      is_closing = function() return false end,
      terminate = function() end,
    }
  end
end

return M
