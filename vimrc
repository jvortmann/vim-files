"set the initial configuration
source $HOME/.vim/conf/init
"load the plugins
source $HOME/.vim/conf/plugins/init
"load the default options
source $HOME/.vim/conf/defaults
"load the autocmd options
source $HOME/.vim/conf/autocmd
"load the gui options
source $HOME/.vim/conf/guioptions
"load plugins configuration
source $HOME/.vim/conf/plugins/settings
"load shortcuts
source $HOME/.vim/conf/shortcuts
"load local vimrc file if it exists
if filereadable(expand("$HOME/.vimrc.local"))
  source $HOME/.vimrc.local
endif
"load extra customization (after variables set on vimrc.local)
source $HOME/.vim/conf/extras
