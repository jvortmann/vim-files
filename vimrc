colorscheme candycode

set nocompatible

call pathogen#runtime_append_all_bundles()
call pathogen#helptags()

filetype indent plugin on
set number tabstop=2 sw=2 bs=2 mouse=a
set ignorecase smartcase showmatch hlsearch incsearch
set ruler title cursorline
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
" hide toolbar by default
set go-=T
set go-=L
set go-=r
" enable syntax highligh
syntax on
" set the space from the current line when scrolling
set scrolloff=3
" set the colors when using terminal commands
set noguipty
" command-line completion shows a list of matches
set wmnu
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

"load the status line
source ~/.vim/conf/statusline
"load shortcuts
source ~/.vim/conf/shortcuts
"load plugins configuration
source ~/.vim/conf/plugins

