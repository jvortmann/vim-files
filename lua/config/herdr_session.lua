local M = {}

local start, save

-- The session starts only in a Herdr terminal where the shell started nvim, so not in an nvim inside nvim.
-- The shell sets HERDR_RESTORE_NVIM to 1 for an nvim command. Nvim removes it, so a program that nvim starts, such as
-- the editor of a commit message, does not get it.
function M.setup()
  local terminal = vim.env.HC_TERMINAL_ID
  local from_shell = vim.env.HERDR_RESTORE_NVIM == '1'
  vim.env.HERDR_RESTORE_NVIM = nil
  if not terminal or terminal == '' or (vim.env.NVIM or '') ~= '' or not from_shell then
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
    -- The save waits until no event came for vim.g.herdr_session_quiet_ms, 500 milliseconds by default.
    callback = function()
      timer:start(vim.g.herdr_session_quiet_ms or 500, 0, vim.schedule_wrap(function() save(file) end))
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    -- A quit the user chose, :qa or :cq, removes the file. A signal, a crash or a lost terminal keeps it. A lost
    -- terminal leaves v:dying at 0, so only the missing UI tells it from :cq.
    callback = function()
      if vim.v.dying == 0 and #vim.api.nvim_list_uis() > 0 then
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
