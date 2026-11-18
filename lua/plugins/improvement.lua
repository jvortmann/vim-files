-- improvement
return {
  { 'junegunn/fzf', build = function() vim.fn['fzf#install']() end },
  { 'junegunn/fzf.vim' },
  { 'sunaku/vim-shortcut' }, -- search shortcuts
  { 'tpope/vim-unimpaired' },
  { 'tpope/vim-repeat' },
  {
    'tpope/vim-ragtag',
    init = function()
      -- activate the global shortcuts for ragtag
      vim.g.ragtag_global_maps = 1
    end,
  },
  { 'tpope/vim-surround' },
  { 'tpope/vim-endwise' },
  { 'kopischke/vim-fetch' }, -- fetch process line and column jump specifications
  { 'kana/vim-textobj-user' }, -- textobj
  { 'wellle/targets.vim' }, -- textobj
  {
    'scrooloose/nerdcommenter',
    init = function()
      -- disabling the default mappings for the NERDCommenter
      vim.g.NERDCreateDefaultMappings = 0
    end,
  },
  { 'scrooloose/nerdtree', cmd = 'NERDTreeToggle' },
  {
    'Townk/vim-autoclose',
    init = function()
      -- make auto close not to flush the keys
      vim.g.AutoClosePreservDotReg = 0
    end,
  },
  {
    'majutsushi/tagbar',
    cmd = { 'Tagbar', 'TagbarOpenAutoClose' },
    init = function()
      -- configuring tagbar
      vim.g.tagbar_width = 60

      vim.g.tagbar_type_elixir = {
        ctagstype = 'elixir',
        kinds = {
          'f:functions',
          'functions:functions',
          'c:callbacks',
          'd:delegates',
          'e:exceptions',
          'i:implementations',
          'a:macros',
          'o:operators',
          'm:modules',
          'p:protocols',
          'r:records',
        },
      }

      vim.g.tagbar_type_go = {
        ctagstype = 'go',
        kinds = {
          'p:package',
          'f:function',
          'v:variables',
          't:type',
          'c:const',
        },
      }

      vim.g.tagbar_type_ruby = {
        kinds = {
          'm:modules',
          'c:classes',
          'd:describes',
          'C:contexts',
          'f:methods',
          'F:singleton methods',
        },
      }

      vim.g.tagbar_type_rust = {
        ctagstype = 'rust',
        kinds = {
          'T:types,type definitions',
          'f:functions,function definitions',
          'g:enum,enumeration names',
          's:structure names',
          'm:modules,module names',
          'c:consts,static constants',
          't:traits,traits',
          'i:impls,trait implementations',
        },
      }

      vim.g.tagbar_type_scala = {
        ctagstype = 'scala',
        sro = '.',
        kinds = {
          'p:packages',
          'T:types:1',
          't:traits',
          'o:objects',
          'O:case objects',
          'c:classes',
          'C:case classes',
          'm:methods',
          'V:values:1',
          'v:variables:1',
        },
      }
    end,
  },
  { 'Shougo/neosnippet' },
  { 'Shougo/neosnippet-snippets' },
  { 'airblade/vim-gitgutter' },
  {
    'vim-airline/vim-airline',
    init = function()
      -- set airline to use powerline symbols from different font
      vim.g.airline_powerline_fonts = 0
      vim.g.airline_left_sep = ''
      vim.g.airline_right_sep = ''

      vim.g['airline#extensions#branch#enabled'] = 0
      vim.g['airline#extensions#hunks#enabled'] = 0

      -- if file is already utf-8, does not show this info
      vim.g['airline#parts#ffenc#skip_expected_string'] = 'utf-8[unix]'
    end,
  },
  { 'vim-airline/vim-airline-themes' },
  { 'godlygeek/tabular' },
  { 'yssl/QFEnter' },
}
