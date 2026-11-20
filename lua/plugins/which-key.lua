return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      -- Names for the fzf maps, which stay VimScript in conf/shortcuts/fzf.shortcuts.
      spec = {
        {
          mode = { 'n', 'x', 's', 'o' },
          { '<leader>ff', desc = 'Find files' },
          { '<leader>fl', desc = 'Find lines in current buffer' },
          { '<leader>fla', desc = 'Find lines in open buffers' },
          { '<leader>fm', desc = 'Find marks' },
          { '<leader>fo', desc = 'Find open buffers' },
          { '<leader>ft', desc = 'Find tags on current buffer' },
          { '<leader>fta', desc = 'Find tags' },
          { '<leader>fh', desc = 'Find files history' },
          { '<leader>f', desc = 'Find files (fallback)' },
          { '<leader>o', desc = 'Find open buffers (fallback)' },
        },
      },
    },
    keys = {
      {
        '<leader>h',
        function() require('which-key').show({ global = true }) end,
        mode = { 'n', 'x' },
        desc = 'Show all shortcuts',
      },
    },
  },
}
