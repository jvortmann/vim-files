return {
  { -- preview registers content for @ and "
    'junegunn/vim-peekaboo',
    init = function()
      -- set size
      vim.g.peekaboo_window = 'vert bo 65new'
    end,
  },
}
