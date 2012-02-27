" vim: filetype=vim
" active when using the gui
" set the initial window size
set co=160
set lines=50
if has("mac")
  " enabling the use of the meta key (alt/option) on the Mac
  set macmeta
endif
" add marker for when changing something
set cpo+=$

" setup powerline
if exists('g:enable_powerline')
  hi StatusLine guifg=#262626 guibg=fg
endif
