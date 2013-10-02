" vim: filetype=vim
"Settings for GUI
"Sets a different colorscheme for GUI
colorscheme luna
" set the initial window size
set co=160
set lines=50
" enabling the use of the meta key (alt/option) on the Mac
if has("mac")
  set macmeta
endif
" make fullscreen the default
set fullscreen
set fuoptions=maxvert,maxhorz
" Remove all the UI cruft
set go-=T
set go-=l
set go-=L
set go-=r
set go-=R

" add marker for when changing something
set cpo+=$

" Set spellcheck settings
highlight SpellBad term=underline gui=undercurl guisp=Orange

if g:use_custom_cursors
  " Cursor color for diferent {{{
  hi Cursor          guifg=#000000 guibg=#AAF412
  hi iCursor         guifg=#000000 guibg=#66D9EF
  hi vCursor         guifg=#000000 guibg=#FD971F
  hi rCursor         guifg=#000000 guibg=#D80000
  " }}}

  " Different cursors for different modes.
  set guicursor=n-c:block-Cursor-blinkon0
  set guicursor+=v:block-vCursor-blinkon0
  set guicursor+=i-ci:ver20-iCursor
  set guicursor+=r-cr:hor20-rCursor
endif

"Sets a better font depending on system
function! s:initialize_font()
  if exists("&guifont")
    if has("mac")
      set guifont=Monaco:h14
    elseif has("unix")
      if &guifont == ""
        set guifont=bitstream\ vera\ sans\ mono\ 12
      endif
    elseif has("win32")
      set guifont=Consolas:h11,Courier\ New:h12
    endif
  endif
endfunction
augroup RCVisual
  autocmd!
  autocmd GUIEnter *  call s:initialize_font()
augroup END
