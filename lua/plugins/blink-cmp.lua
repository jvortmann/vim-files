return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = { preset = 'default', ['<CR>'] = { 'accept', 'fallback' } },
      completion = { list = { selection = { preselect = false } } },
      cmdline = { enabled = false },
    },
  },
}
