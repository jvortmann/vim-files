return {
  {
    'yssl/QFEnter',
    init = function()
      -- QFEnter no longer reads g:qfenter_vopen_map and g:qfenter_hopen_map.
      vim.g.qfenter_keymap = {
        vopen = { '<C-v>', 'v', '<Leader><CR>' },
        hopen = { '<C-CR>', '<C-s>', '<C-x>', 's', '<Leader><Space>' },
      }
    end,
  },
}
