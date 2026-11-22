local M = {}

-- Connects to the RPC socket at path, and returns the channel, or nil when the connect fails.
-- Neovim makes the socket file a moment before it listens on it, so a connect right after the file appears can fail.
-- A caller retries it until it gets a channel.
function M.connect(path)
  local ok, channel = pcall(vim.fn.sockconnect, 'pipe', path, { rpc = true })
  return ok and channel or nil
end

return M
