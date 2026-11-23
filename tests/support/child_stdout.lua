-- Starts a child Neovim with this config and args. Returns a function that waits up to 10 seconds for the child and
-- returns its stdout. Start all children before the first wait, so they run at the same time.
return function(args)
  local child = vim.system(vim.list_extend({ vim.v.progpath, '-i', 'NONE', '--headless' }, args), { stdin = false, text = true })
  return function()
    local result = child:wait(10000)
    return result and result.stdout or ''
  end
end
