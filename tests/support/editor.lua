local M = {}

local support_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local mason = dofile(support_dir .. '/mason.lua')
local rpc = dofile(support_dir .. '/rpc.lua')

-- Starts a child Neovim with this config. It returns when VeryLazy has run, as in an editor where a user types.
-- opts.cwd is the directory of the child, and opts.files lists the files that it opens.
-- opts.args lists more arguments, which come before the files.
-- opts.env sets environment variables of the child. The value false removes the variable.
-- The child loads the fake mason registry, so it installs no language server.
function M.start(opts)
  opts = opts or {}
  local socket = vim.fn.tempname()
  local command = vim.list_extend({ vim.v.progpath, '-i', 'NONE', '--headless', '--listen', socket }, mason.args())
  vim.list_extend(vim.list_extend(command, opts.args or {}), opts.files or {})
  local env, removed = {}, {}
  for name, value in pairs(opts.env or {}) do
    if value then
      env[name] = value
    else
      vim.list_extend(removed, { '-u', name })
    end
  end
  -- jobstart() always sets NVIM in the child, so only the env command can remove it.
  if #removed > 0 then
    command = vim.list_extend(vim.list_extend({ 'env' }, removed), command)
  end
  local stderr, exit_code = {}, nil
  local job = vim.fn.jobstart(command, {
    cwd = opts.cwd or vim.fn.getcwd(),
    env = next(env) and env or nil,
    on_stderr = function(_, data) table.insert(stderr, table.concat(data, '\n')) end,
    on_exit = function(_, code) exit_code = code end,
  })
  assert(job > 0, 'the child Neovim did not start: ' .. table.concat(command, ' '))
  local editor
  assert(
    vim.wait(5000, function()
      editor = exit_code == nil and rpc.connect(socket) or nil
      return exit_code ~= nil or editor ~= nil
    end),
    'the child Neovim opened no socket'
  )
  if exit_code then
    error(('the child Neovim exited with %d before it opened its socket: %s'):format(exit_code, table.concat(stderr)))
  end
  assert(
    vim.wait(5000, function() return vim.rpcrequest(editor, 'nvim_get_vvar', 'vim_did_enter') == 1 end),
    'the child Neovim did not reach VimEnter'
  )
  -- A headless Neovim never fires UIEnter, and lazy.nvim fires VeryLazy only after it. Fire UIEnter by hand.
  vim.rpcrequest(editor, 'nvim_exec_lua', [[
    vim.api.nvim_exec_autocmds('UIEnter', { modeline = false })
    vim.schedule(function() vim.schedule(function() vim.g.test_started = true end) end)
  ]], {})
  assert(
    vim.wait(5000, function() return vim.rpcrequest(editor, 'nvim_exec_lua', 'return vim.g.test_started', {}) == true end),
    'the child Neovim did not run VeryLazy'
  )
  return editor, job
end

return M
