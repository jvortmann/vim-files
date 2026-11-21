return {
  {
    'christoomey/vim-tmux-navigator', -- navigate seamsly between tmux and vim splits
    config = function()
      if (vim.env.HC_TERMINAL_ID or '') == '' then
        return
      end
      for command, move in pairs({
        TmuxNavigateLeft = { 'h', 'left' },
        TmuxNavigateDown = { 'j', 'down' },
        TmuxNavigateUp = { 'k', 'up' },
        TmuxNavigateRight = { 'l', 'right' },
      }) do
        vim.api.nvim_create_user_command(command, function()
          local window = vim.api.nvim_get_current_win()
          vim.cmd.wincmd(move[1])
          if vim.api.nvim_get_current_win() ~= window then
            return
          end
          local app = vim.g.herdr_app or vim.fn.expand('~/.local/bin/herdr-app')
          pcall(vim.system, { app, 'do', 'pane.go', vim.json.encode({ direction = move[2] }) }, { stdout = false, stderr = false })
        end, {})
      end
    end,
  },
}
