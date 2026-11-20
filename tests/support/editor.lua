local M = {}

-- Starts a child Neovim with this config. It returns when VeryLazy has run, as in an editor where a user types.
-- opts.cwd is the directory of the child, and opts.files lists the files that it opens.
function M.start(opts)
  opts = opts or {}
  local socket = vim.fn.tempname()
  local command = vim.list_extend({ vim.v.progpath, '-i', 'NONE', '--headless', '--listen', socket }, opts.files or {})
  local job = vim.fn.jobstart(command, { cwd = opts.cwd or vim.fn.getcwd() })
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
