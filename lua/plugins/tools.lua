-- tools
return {
  {
    'prettier/vim-prettier',
    build = 'yarn install --frozen-lockfile --production',
    ft = { 'javascript', 'typescript', 'css', 'less', 'scss', 'json', 'ruby', 'markdown', 'yaml', 'html' },
  },
  { 'dense-analysis/ale' }, -- [SLOW] check syntax fix files
  { 'itchyny/vim-qfedit' }, -- quickfix
  { 'junegunn/vim-peekaboo' }, -- preview registers content for @ and "
  { 'mattn/gist-vim' }, -- github gist
  { 'mattn/webapi-vim' }, -- gist dependency
  { 'mileszs/ack.vim' }, -- search
  { 'radenling/vim-dispatch-neovim' }, -- dispatch
  { 'romainl/vim-devdocs' }, -- devdocs
  { 'tmux-plugins/vim-tmux' }, -- tmux
  { 'christoomey/vim-tmux-navigator' }, -- navigate seamsly between tmux and vim splits
  { 'tpope/vim-dispatch' }, -- dispatch
  { 'tpope/vim-fugitive' }, -- git
  { 'tpope/vim-git' }, -- git
  { 'tpope/vim-projectionist' }, -- projectionist
}
