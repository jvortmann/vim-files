return {
  { -- search
    'mileszs/ack.vim',
    init = function()
      -- set smart-grep and ag as default engines for Ack
      if vim.fn.executable('rg') == 1 then
        vim.g.ackprg = "rg --hidden --vimgrep -g '!.git' -g '!/vendor'"
      end

      vim.g.ack_mappings = {
        h = '',
        s = '<C-W><CR><C-W>K',
        v = '<C-W><CR><C-W>H<C-W>b<C-W>J<C-W>t',
      }

      -- highlight the search term
      vim.g.ackhighlight = 1
    end,
  },
}
