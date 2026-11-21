-- Maps each language server to the mason package that installs it.
-- This map replaces mason-lspconfig, whose own map needs the downloaded registry.
return {
  eslint = 'eslint-lsp',
  gopls = 'gopls',
  lua_ls = 'lua-language-server',
  ruby_lsp = 'ruby-lsp',
  rust_analyzer = 'rust-analyzer',
  vtsls = 'vtsls',
  zls = 'zls',
}
