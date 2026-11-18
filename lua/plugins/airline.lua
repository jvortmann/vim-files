return {
  {
    'vim-airline/vim-airline',
    init = function()
      -- set airline to use powerline symbols from different font
      vim.g.airline_powerline_fonts = 0
      vim.g.airline_left_sep = ''
      vim.g.airline_right_sep = ''

      vim.g['airline#extensions#branch#enabled'] = 0
      vim.g['airline#extensions#hunks#enabled'] = 0

      -- if file is already utf-8, does not show this info
      vim.g['airline#parts#ffenc#skip_expected_string'] = 'utf-8[unix]'
    end,
  },
  { 'vim-airline/vim-airline-themes' },
}
