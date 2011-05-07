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
" display a warning if file encoding isnt utf-8
set statusline=
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
" set the format of the status line
set statusline+=%*
set statusline+=%h              "help file flag
set statusline+=%y              "filetype
set statusline+=%r              "read only flag
set statusline+=%m              "modified flag
set statusline+=%=              "left/right separator
set statusline+=%*              "show the errors/warning in the status line
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
set statusline+=%=              "left/right separator
set statusline+=[%l,%c]         "cursor line,column
set statusline+=\ \|%L\ lines\| "/total lines
set statusline+=\ %P            "percent through file
set laststatus=2
" folding settings
set foldmethod=indent   "fold based on indent
set foldnestmax=3       "deepest fold is 3 levels
set nofoldenable        "dont fold by default
" improve the autocomplete menu
set completeopt=longest,menuone

"load shortcuts
source ~/.vim/conf/shortcuts
"load plugins configuration
source ~/.vim/conf/plugins

