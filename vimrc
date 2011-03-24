colorscheme candycode
set nocompatible
filetype indent on
filetype plugin on
let g:ragtag_global_maps = 1
set number tabstop=2 sw=2 bs=2 mouse=a
set ignorecase smartcase showmatch hlsearch incsearch
set ruler title cursorline
" enable auto-saving
set autowriteall
" active when using the gui
if has("gui_running")
  " enabling the use of the meta key (alt/option) on the Mac
  set macmeta
  " set the initial window size
  set co=160
  set lines=50
endif
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
" set the colors when using terminal commands
set noguipty
" command-line completion shows a list of matches
set wmnu
" allow backspacing over everything in insert mode
set backspace=indent,eol,start
" display a warning if file encoding isnt utf-8
set statusline+=%#warningmsg#
set statusline+=%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}
" set the format of the status line
set statusline+=%*
set statusline+=%h              "help file flag
set statusline+=%y              "filetype
set statusline+=%r              "read only flag
set statusline+=%m              "modified flag
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
:set completeopt=longest,menuone
:inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
inoremap <expr> <C-n> pumvisible() ? '<C-n>' : '<C-n><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
inoremap <expr> <M-,> pumvisible() ? '<C-n>' : '<C-x><C-o><C-n><C-p><C-r>=pumvisible() ? "\<lt>Down>" : ""<CR>'
" map the F2 key to open a side panel with the folder tree
noremap <F2> :NERDTreeToggle<Return>
" set Control-Shift-{j-k} to move lines up and down
" set Control-Shift-{Down-Up} to move lines up and down
nnoremap <M-S-Down> :m+<CR>==
nnoremap <M-S-Up> :m-2<CR>==
inoremap <M-S-Down> <Esc>:m+<CR>==gi
inoremap <M-S-Up> <Esc>:m-2<CR>==gi
vnoremap <M-S-Down> :m'>+<CR>gv=gv
vnoremap <M-S-Up> :m-2<CR>gv=gv
" set Command-Shift-t to search for files 
noremap <M-S-f>f :FufFile **/<CR>
noremap <M-S-o> :FufBuffer **/<CR>
" set mapping to Rails plugin
noremap <M-S-m> :Rmodel<Space>
noremap <M-S-c> :Rcontroller<Space>
noremap <M-S-v> :Rview<Space>
noremap <M-S-s> :Rscript<Space>
noremap <M-S-e> :Rextract<Space>
noremap <M-S-g> :Rgenerate<Space>
noremap <M-S-l> :Rlog<CR>
noremap <M-S-p> :Rpreview<CR>
noremap <M-S-f>r :Rfind<Space>
noremap <F3> :A<CR>
noremap <F4> :R<CR>
" set mapping to run rake tests
noremap <F5> :Rake<CR>
noremap <F6> :.Rake<CR>
" set mapping to Fugitive plugin
noremap <F7> :Gblame<CR>
noremap <S-F7> :Gdiff<CR>
" set mapping to move between tabs
noremap <C-S-Right> gt
nmap <C-Tab> gt
noremap <C-S-Left> gT
nmap <C-S-Tab> gT
" set mapping to navigate between open split windows
noremap <C-h> <C-w><Left>
noremap <C-j> <C-w><Down>
noremap <C-k> <C-w><Up>
noremap <C-l> <C-w><Right>
" set mapping expand the window
noremap <Space><Space> <C-w>_
noremap <Space>= <C-w>=
" set mapping to duplicate lines
noremap <M-S-d> Yp
" shortcut to select all
noremap <M-a> ggVG
" set mapping to autocomplete
imap <S-Space> <C-x><C-p>
" roll down and roll up
noremap <C-Down> <C-d>
noremap <C-Up> <C-u>
