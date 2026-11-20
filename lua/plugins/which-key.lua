return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {},
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
