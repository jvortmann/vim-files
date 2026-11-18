return {
  { -- css
    'ap/vim-css-color',
    ft = { 'css', 'sass', 'scss', 'less' },
    init = function()
      -- make css color not change the update time to crazy 100ms
      vim.g.cssColorVimDoNotMessMyUpdatetime = 1
    end,
  },
}
