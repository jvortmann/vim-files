" vim: filetype=vim
" active when using the gui
" set the initial window size
set co=160
set lines=50
if has("mac")
  " enabling the use of the meta key (alt/option) on the Mac
  set macmeta
  " make fullscreen the default
  set fullscreen
endif
" add marker for when changing something
set cpo+=$
