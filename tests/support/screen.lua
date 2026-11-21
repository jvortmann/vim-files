local M = {}

local mason = dofile(vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/mason.lua')

local started = 0

-- Starts Neovim with this config in a tmux pane of opts.width by opts.height cells, and waits for VimEnter.
-- opts.cwd is the directory of Neovim, and opts.args lists its arguments, such as the files that it opens.
-- It returns run(code, ...), which runs Lua in that Neovim, rows(colors), which reads the rows of the pane,
-- and stop(), which ends the tmux server. With colors true, the rows keep the color escape codes.
-- The Neovim loads the fake mason registry, so it installs no language server.
function M.start(opts)
  started = started + 1
  local server = ('screen_test_%d_%d'):format(vim.fn.getpid(), started)
  local socket = vim.fn.tempname()
  -- The empty HC_TERMINAL_ID keeps the Neovim from saving a Herdr session when the suite runs in Herdr.
  local command = {
    'tmux', '-L', server, '-f', '/dev/null', 'new-session', '-d', '-e', 'HC_TERMINAL_ID=',
    '-x', tostring(opts.width or 40), '-y', tostring(opts.height or 10), '-c', opts.cwd or vim.fn.getcwd(),
    vim.v.progpath, '-i', 'NONE', '--listen', socket,
  }
  vim.list_extend(command, mason.args())
  vim.fn.system(vim.list_extend(command, opts.args or {}))
  local screen = {}
  function screen.stop()
    vim.fn.system({ 'tmux', '-L', server, 'kill-server' })
  end
  if not vim.wait(5000, function() return vim.uv.fs_stat(socket) ~= nil end) then
    screen.stop()
    error('the Neovim in tmux opened no socket')
  end
  local editor = vim.fn.sockconnect('pipe', socket, { rpc = true })
  vim.wait(5000, function() return vim.rpcrequest(editor, 'nvim_get_vvar', 'vim_did_enter') == 1 end)
  function screen.run(code, ...)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
  end
  function screen.rows(colors)
    local capture = { 'tmux', '-L', server, 'capture-pane', '-p' }
    if colors then
      table.insert(capture, '-e')
    end
    return vim.split(vim.fn.system(capture), '\n')
  end
  return screen
end

return M
