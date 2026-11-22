return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-k>'] = {
          function(cmp)
            if #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/signatureHelp' }) > 0 then
              return cmp.show_signature()
            end
          end,
          'hide_signature',
          'fallback',
        },
      },
      completion = { list = { selection = { preselect = false } } },
      cmdline = {
        completion = { list = { selection = { preselect = false } }, menu = { auto_show = true } },
      },
      signature = { enabled = true },
    },
  },
}
