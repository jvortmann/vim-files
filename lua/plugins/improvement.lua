-- improvement
return {
  { 'junegunn/fzf', build = function() vim.fn['fzf#install']() end },
  { 'junegunn/fzf.vim' },
  { 'sunaku/vim-shortcut' }, -- search shortcuts
  { 'tpope/vim-unimpaired' },
  { 'tpope/vim-repeat' },
  { 'tpope/vim-ragtag' },
  { 'tpope/vim-surround' },
  { 'tpope/vim-endwise' },
  { 'kopischke/vim-fetch' }, -- fetch process line and column jump specifications
  { 'kana/vim-textobj-user' }, -- textobj
  { 'wellle/targets.vim' }, -- textobj
  { 'scrooloose/nerdcommenter' },
  { 'scrooloose/nerdtree', cmd = 'NERDTreeToggle' },
  { 'Townk/vim-autoclose' },
  { 'majutsushi/tagbar', cmd = { 'Tagbar', 'TagbarOpenAutoClose' } },
  { 'Shougo/neosnippet' },
  { 'Shougo/neosnippet-snippets' },
  { 'airblade/vim-gitgutter' },
  { 'vim-airline/vim-airline' },
  { 'vim-airline/vim-airline-themes' },
  { 'godlygeek/tabular' },
  { 'yssl/QFEnter' },
}
