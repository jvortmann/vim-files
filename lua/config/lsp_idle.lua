-- Stops a language server whose buffers see no use for vim.g.lsp_idle_ms, one hour by default.
local M = {}

local last_use = {}
local stopped = {}
local check, use

function M.setup()
  local group = vim.api.nvim_create_augroup('LspIdle', { clear = true })
  -- Each event only writes the time of the use, so a cursor move costs one table write.
  vim.api.nvim_create_autocmd(
    { 'LspAttach', 'BufEnter', 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI', 'BufWritePost' },
    {
      group = group,
      callback = function(args) use(args.buf) end,
    }
  )
  local timer = vim.uv.new_timer()
  local interval = vim.g.lsp_idle_check_ms or 5 * 60 * 1000
  timer:start(interval, interval, vim.schedule_wrap(check))
end

function check()
  local limit = vim.g.lsp_idle_ms or 60 * 60 * 1000
  local now = vim.uv.now()
  for _, client in ipairs(vim.lsp.get_clients()) do
    local latest = 0
    for buf in pairs(client.attached_buffers) do
      latest = math.max(latest, last_use[buf] or 0)
    end
    if now - latest >= limit then
      local buffers = vim.tbl_keys(client.attached_buffers)
      for _, buf in ipairs(buffers) do
        stopped[buf] = buffers
      end
      client:stop()
    end
  end
end

function use(buf)
  last_use[buf] = vim.uv.now()
  local buffers = stopped[buf]
  if not buffers then
    return
  end
  -- Runs the start of vim.lsp.enable on each buffer of the stopped server, so the root is found as when the file opened.
  for _, server_buf in ipairs(buffers) do
    stopped[server_buf] = nil
    if vim.api.nvim_buf_is_loaded(server_buf) then
      pcall(vim.api.nvim_exec_autocmds, 'FileType', { group = 'nvim.lsp.enable', buffer = server_buf })
    end
  end
end

return M
