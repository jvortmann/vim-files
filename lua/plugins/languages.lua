-- languages and frameworks
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    -- nvim-treesitter (main-branch rewrite)
    -- https://github.com/nvim-treesitter/nvim-treesitter
    --
    -- The old `require('nvim-treesitter.configs').setup{}` module was removed.
    -- This branch only installs parsers and ships queries; activating features
    -- (highlight, indent) is done through Neovim core, per buffer.
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

      -- Enable treesitter highlighting and (experimental) indentation per buffer
      -- whenever a parser is available for the buffer's filetype.
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('nvim_treesitter_start', { clear = true }),
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  { 'aliou/bats.vim', ft = 'bats' }, -- bats
  { 'tpope/vim-fireplace', ft = 'clojure' }, -- clojure
  { -- css
    'ap/vim-css-color',
    ft = { 'css', 'sass', 'scss', 'less' },
    init = function()
      -- make css color not change the update time to crazy 100ms
      vim.g.cssColorVimDoNotMessMyUpdatetime = 1
    end,
  },
  { 'slashmili/alchemist.vim', ft = 'elixir' }, -- elixir
  { 'avdgaag/vim-phoenix', ft = 'elixir' }, -- elixir phoenix
  { 'andyl/vim-textobj-elixir', ft = 'elixir' }, -- elixir textobj
  { 'janko/vim-test' }, -- test runner
  { -- [SLOW] ruby rspec
    'keith/rspec.vim',
    ft = 'ruby',
    -- lazy.nvim sources ftdetect but not after/ftdetect, where rspec.vim keeps its detection.
    -- An init runs at startup, so the detection works before the plugin loads.
    init = function(plugin)
      vim.cmd('augroup filetypedetect')
      vim.cmd.source(plugin.dir .. '/after/ftdetect/rspec.vim')
      vim.cmd('augroup END')
    end,
  },
  { 'slim-template/vim-slim' }, -- slim template
  { 'tpope/vim-rake', ft = 'ruby' }, -- ruby rake
  { 'ngmy/vim-rubocop', ft = 'ruby' }, -- ruby rubocop
  { 'nelstrom/vim-textobj-rubyblock', ft = 'ruby' }, -- ruby textobj
}
