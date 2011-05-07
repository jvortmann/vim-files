"load the initial configuration
source ~/.vim/conf/init

set nocompatible

filetype indent plugin on
set ignorecase smartcase showmatch hlsearch incsearch
" enable auto write read and hidden of files
set autowriteall
set autoread
set hidden
" set proper encoding for files
set encoding=utf-8
set fileencoding=utf-8
" spaces instead of tabs
set sta
set et
" enable syntax highligh
syntax on
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
" set the history to display more itens
set history=100
" set the undo to have a thousand entries
set undolevels=1000
" folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=3       "deepest fold is 3 levels
set nofoldenable        "dont fold by default
" improve the autocomplete menu
set completeopt=longest,menuone

"load the gui options
source ~/.vim/conf/guioptions
"load the status line
source ~/.vim/conf/statusline
"load shortcuts
source ~/.vim/conf/shortcuts
"load plugins configuration
source ~/.vim/conf/plugins
