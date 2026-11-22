-- Install lazy.nvim if not present
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' }, { out, 'WarningMsg' } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  spec = {
    { import = 'plugins' },
  },
  checker = { enabled = false },
  change_detection = { notify = false },
  rocks = { enabled = false },
  performance = { rtp = { reset = false } },
})
