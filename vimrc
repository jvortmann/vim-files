"load the initial configuration
source $HOME/.vim/conf/init
"load the default options
source $HOME/.vim/conf/defaults
"load the gui options
source $HOME/.vim/conf/guioptions
"load shortcuts
source $HOME/.vim/conf/shortcuts
"load plugins configuration
source $HOME/.vim/conf/plugins
"load local  if they exist
if filereadable(expand("$HOME/.vimrc.local"))
  source $HOME/.vimrc.local
endif
