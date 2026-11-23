local M = {}

local label

function M.setup()
  local terminal = vim.env.HC_TERMINAL_ID
  if not terminal or terminal == '' or (vim.env.NVIM or '') ~= '' then
    return
  end
  local group = vim.api.nvim_create_augroup('HerdrServerLabel', { clear = true })
  vim.api.nvim_create_autocmd('UIEnter', {
    group = group,
    once = true,
    callback = function()
      label(terminal, vim.v.servername ~= '' and vim.v.servername or vim.fn.serverstart())
      vim.api.nvim_create_autocmd('VimLeavePre', {
        group = group,
        callback = function() label(terminal, '') end,
      })
    end,
  })
end

function label(terminal, server)
  local hc = vim.g.herdr_hc or vim.fn.expand('~/.local/bin/hc')
  pcall(vim.system, { hc, 'label', terminal, 'nvim.server=' .. server }, { stdout = false, stderr = false })
end

return M
