local servers = vim.tbl_keys(require('config.language_servers'))
table.sort(servers)

return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- A server starts only in a project, never for a single file.
      for _, name in ipairs(servers) do
        vim.lsp.config(name, { workspace_required = true })
      end
      -- lspconfig starts vtsls in the working folder when it finds no project, so check for a project first.
      local vtsls_root_dir = vim.lsp.config.vtsls.root_dir
      vim.lsp.config('vtsls', {
        root_dir = function(bufnr, on_dir)
          if vim.fs.root(bufnr, { 'package-lock.json', 'yarn.lock', 'pnpm-lock.yaml', 'bun.lockb', 'bun.lock', '.git' }) then
            vtsls_root_dir(bufnr, on_dir)
          end
        end,
      })
      vim.lsp.config('ruby_lsp', { filetypes = { 'ruby', 'eruby', 'rspec.ruby' } })
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = { library = { vim.env.VIMRUNTIME } },
            diagnostics = { globals = { 'vim' } },
          },
        },
      })
      vim.lsp.enable(servers)
      require('config.lsp_idle').setup()
    end,
  },
}
