" set the initial configuration
source $HOME/.vim/conf/init
" set the configuration that have precedence (as mapleader)
source $HOME/.vim/conf/first
" load the plugins
source $HOME/.vim/conf/plugins/init
" load the default options
source $HOME/.vim/conf/defaults
" load the autocmd options
source $HOME/.vim/conf/autocmd/init
" load the gui options
source $HOME/.vim/conf/guioptions
" load shortcuts
source $HOME/.vim/conf/shortcuts/init
" load local vimrc file if it exists
if filereadable(expand("$HOME/.vimrc.local"))
  source $HOME/.vimrc.local
endif
" load extra customization (after variables set on vimrc.local)
source $HOME/.vim/conf/extras
" then loads after/plugin/force_configs.vim
" and then your local ~/.vimrc.force for configs 
" that needs to be setup last
