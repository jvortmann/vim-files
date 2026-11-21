local M = {}

-- Returns a cmd for vim.lsp.config or vim.lsp.start that runs a fake server inside this Neovim.
-- The server answers each request with the value of results for its method, or with nil.
-- When diagnostics is a list, the server publishes it for each file that opens.
-- The server exits on the exit notification, or when the client terminates it.
function M.cmd(results, diagnostics)
  return function(dispatchers)
    local id = 0
    local closing = false
    local function exit()
      if not closing then
        closing = true
        vim.schedule(function() dispatchers.on_exit(0, 0) end)
      end
    end
    return {
      request = function(method, _, callback)
        id = id + 1
        callback(nil, results[method])
        return true, id
      end,
      notify = function(method, params)
        if method == 'exit' then
          exit()
        end
        if method == 'textDocument/didOpen' and diagnostics then
          vim.schedule(function()
            dispatchers.notification('textDocument/publishDiagnostics', { uri = params.textDocument.uri, diagnostics = diagnostics })
          end)
        end
        return true
      end,
      is_closing = function() return closing end,
      terminate = exit,
    }
  end
end

return M
