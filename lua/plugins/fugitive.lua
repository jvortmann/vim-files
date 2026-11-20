local nvo = { 'n', 'x', 's', 'o' }

return {
  {
    'tpope/vim-fugitive', -- git
    -- Keys alone would make the plugin lazy. It must load at startup, so that :Git exists.
    lazy = false,
    keys = {
      {
        '<F7>',
        [[filereadable(".git-blame-ignore-revs") ? ':Git blame --ignore-revs-file .git-blame-ignore-revs<CR>' : ':Git blame<CR>']],
        mode = nvo,
        expr = true,
        desc = 'Git blame',
      },
      { '<S-F7>', ':Gvdiffsplit!<CR>', mode = nvo, silent = true, desc = 'Git diff in a vertical split' },
    },
  },
}
