"load the initial configuration
source $HOME/.vim/conf/init
"load the bundles
source $HOME/.vim/conf/bundles
"load the default options
source $HOME/.vim/conf/defaults
"load the autocmd options
source $HOME/.vim/conf/autocmd
"load the gui options
source $HOME/.vim/conf/guioptions
"load plugins configuration
source $HOME/.vim/conf/plugins
"load shortcuts
source $HOME/.vim/conf/shortcuts
"load local  if they exist
if filereadable(expand("$HOME/.vimrc.local"))
  source $HOME/.vimrc.local
endif
