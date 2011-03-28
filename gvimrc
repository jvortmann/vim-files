" active when using the gui
colorscheme molokai
" set the initial window size
set co=160
set lines=50

if system('uname -s') =~ "Darwin"
  " enabling the use of the meta key (alt/option) on the Mac
  set macmeta
endif
