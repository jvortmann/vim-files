return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    event = { 'BufReadPre', 'BufNewFile', 'FileType' },
    -- nvim-treesitter (main-branch rewrite)
    -- https://github.com/nvim-treesitter/nvim-treesitter
    --
    -- The old `require('nvim-treesitter.configs').setup{}` module was removed.
    -- This branch only installs parsers and ships queries; activating features
    -- (highlight, indent) is done through Neovim core, per buffer.
    init = function()
      -- Enable treesitter highlighting and (experimental) indentation per buffer
      -- whenever a parser is available for the buffer's filetype.
      -- This autocmd must run before the syntaxset autocmd of Neovim. That one
      -- skips the regex syntax file only when b:ts_highlight exists. With
      -- syntax/ruby.vim loaded, vim-endwise stops closing a ruby def. The init
      -- function runs in the lazy.nvim setup, before `syntax enable` in
      -- lua/config/defaults.lua creates the syntaxset autocmd. So init.lua must
      -- load config.defaults after config.plugins.init.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('nvim_treesitter_start', { clear = true }),
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
    config = function()
      local ts = require('nvim-treesitter')

      -- Install parsers/queries into stdpath('data')/site (prepended to runtimepath
      -- so freshly built parsers take precedence over any stale ones). Asynchronous;
      -- a no-op when a parser is already installed.
      ts.setup({ install_dir = vim.fn.stdpath('data') .. '/site' })

      ts.install({
        'bash',
        'clojure',
        'css',
        'dockerfile',
        'elixir',
        'elm',
        'erlang',
        'go',
        'gomod',
        'graphql',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'latex',
        'lua',
        'nix',
        'python',
        'regex',
        'rst',
        'ruby',
        'rust',
        'scala',
        'scss',
        'svelte',
        'toml',
        'typescript',
        'tsx',
        'vue',
        'vimdoc',
        'yaml',
      })
    end,
  },
}
