return {
  {
    'nvim-mini/mini.surround',
    config = function()
      -- The vim-surround keys, from the setup in :help MiniSurround-vim-surround-config.
      require('mini.surround').setup({
        mappings = {
          add = 'ys',
          delete = 'ds',
          find = '',
          find_left = '',
          highlight = '',
          replace = 'cs',
          suffix_last = '',
          suffix_next = '',
          -- The default 'sn' map would make s wait for 'timeoutlen'.
          update_n_lines = '',
        },
        search_method = 'cover_or_next',
      })
      vim.keymap.set('n', 'yss', 'ys_', { remap = true })
      vim.keymap.del('x', 'ys')
      vim.keymap.set('x', 'S', [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })
    end,
  },
}
