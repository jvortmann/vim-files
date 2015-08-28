" vim: filetype=vim
"
" All GUI setup is now deprecated
"

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

" Define a font on the GUI
function! s:initialize_font()
  if g:airline_powerline_fonts
    if exists("&guifont") && (&guifont == "")
      set guifont=Sauce\ Code\ Powerline\ Light:h15
    endif
  endif
endfunction
augroup RCVisual
  autocmd!
  autocmd GUIEnter * call s:initialize_font()
augroup END
