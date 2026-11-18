return {
  {
    'Townk/vim-autoclose',
    init = function()
      -- make auto close not to flush the keys
      vim.g.AutoClosePreservDotReg = 0
    end,
  },
}
