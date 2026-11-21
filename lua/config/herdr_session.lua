local M = {}

-- The save waits until no event came for this many milliseconds.
local quiet_ms = 500

local start, save

function M.setup()
  local terminal = vim.env.HC_TERMINAL_ID
  if not terminal or terminal == '' or (vim.env.NVIM or '') ~= '' then
    return
  end
  local group = vim.api.nvim_create_augroup('HerdrSession', { clear = true })
  vim.api.nvim_create_autocmd('UIEnter', {
    group = group,
    once = true,
    callback = function() start(terminal, group) end,
  })
end

function start(terminal, group)
  local file = vim.fn.stdpath('state') .. '/sessions/' .. terminal .. '.vim'
  vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize' }
  local hc = vim.g.herdr_hc or vim.fn.expand('~/.local/bin/hc')
  pcall(vim.system, { hc, 'label', terminal, 'restore.nvim=' .. file }, { stdout = false, stderr = false })
  local timer = vim.uv.new_timer()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinNew', 'WinClosed', 'VimResized', 'CursorHold' }, {
    group = group,
    callback = function() timer:start(quiet_ms, 0, vim.schedule_wrap(function() save(file) end)) end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if vim.v.dying == 0 and vim.v.exiting == 0 then
        os.remove(file)
      else
        save(file)
      end
    end,
  })
end

function save(file)
  vim.fn.mkdir(vim.fs.dirname(file), 'p')
  pcall(vim.cmd, 'mksession! ' .. vim.fn.fnameescape(file))
end

return M
