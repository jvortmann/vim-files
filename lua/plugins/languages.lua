-- languages and frameworks
return {
  { 'nvim-treesitter/nvim-treesitter', branch = 'main', build = ':TSUpdate' },
  { 'aliou/bats.vim', ft = 'bats' }, -- bats
  { 'tpope/vim-fireplace', ft = 'clojure' }, -- clojure
  { 'ap/vim-css-color', ft = { 'css', 'sass', 'scss', 'less' } }, -- css
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
