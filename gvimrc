" vim: filetype=vim

" enabling the use of the meta key (alt/option) on the Mac
if has("mac")
  set macmeta
endif
" make fullscreen the default
set fullscreen
set fuoptions=maxvert,maxhorz
" Remove all the UI cruft
set go=egm

" load local gvimrc file if it exists
if filereadable(expand("$HOME/.gvimrc.local"))
  source $HOME/.gvimrc.local
endif
