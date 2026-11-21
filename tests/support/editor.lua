local M = {}

-- Starts a child Neovim with this config. It returns when VeryLazy has run, as in an editor where a user types.
-- opts.cwd is the directory of the child, and opts.files lists the files that it opens.
-- opts.args lists more arguments, which come before the files.
-- opts.env sets environment variables of the child. The value false removes the variable.
function M.start(opts)
  opts = opts or {}
  local socket = vim.fn.tempname()
  local command = { vim.v.progpath, '-i', 'NONE', '--headless', '--listen', socket }
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
  local job = vim.fn.jobstart(command, { cwd = opts.cwd or vim.fn.getcwd(), env = next(env) and env or nil })
  assert(vim.wait(5000, function() return vim.uv.fs_stat(socket) ~= nil end), 'the child Neovim opened no socket')
  local editor = vim.fn.sockconnect('pipe', socket, { rpc = true })
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
