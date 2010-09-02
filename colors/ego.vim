" Vim color file
" Maintainer: Robby Colvin
" Last Change: 2010-04-30
" Version: 0.1
" based on 'ego' theme for Xcode:
" http://developers.enormego.com/view/xcode_ego_theme

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let g:colors_name = "ego"

" GUI Colors
hi Cursor               gui=NONE guibg=#8DA1A1 guifg=#ffffff
hi CursorIM             gui=bold guifg=#ffffff guibg=#8DA1A1
hi CursorLine           gui=NONE guibg=#3D4646 " Uncomment for lighter line bgcolor: #202129
hi CursorColumn         gui=NONE guibg=#3D4646 " Uncomment for lighter line bgcolor: #202129
hi Directory            gui=NONE guifg=#82c057 guibg=bg
hi DiffAdd              gui=NONE guifg=fg      guibg=#9bb2ee
hi DiffChange           gui=NONE guifg=fg      guibg=#82c057
hi DiffDelete           gui=NONE guifg=fg      guibg=#000000
hi DiffText             gui=bold guifg=fg      guibg=bg
hi ErrorMsg             gui=NONE guifg=#FFFF99 guibg=#FF0000
hi VertSplit            gui=NONE guifg=#000000 guibg=#686868
hi Folded               gui=bold guibg=#305060 guifg=#b0d0e0
hi FoldColumn           gui=NONE guibg=#305060 guifg=#b0d0e0
hi IncSearch            gui=reverse guifg=fg guibg=bg
hi LineNr               gui=NONE guibg=#000000 guifg=#686868
hi ModeMsg              gui=NONE guibg=#82c057 guifg=#C8F482
hi MoreMsg              gui=bold guifg=#C8F482 guibg=bg
hi NonText              gui=NONE guibg=#000000 guifg=#95D5F1
hi Normal               gui=NONE guibg=#18191F guifg=#F6F6F6
hi Question             gui=bold guifg=#C8F482 guibg=bg
hi Search               gui=NONE guibg=#95D5F1 guifg=#18191F
hi SpecialKey           gui=NONE guibg=#103040 guifg=#324262
hi StatusLine           gui=bold guibg=#484848 guifg=#000000
hi StatusLineNC         gui=NONE guibg=#686868  guifg=#E0E0E0
hi Title                gui=bold guifg=#9d7ff2 guibg=bg
hi Visual               gui=reverse guibg=#ffffff guifg=#55747c
hi VisualNOS            gui=bold,underline guifg=fg guibg=bg
hi WarningMsg           gui=bold guifg=#FF0000 guibg=bg
hi WildMenu             gui=bold guibg=#F6DA7B guifg=#000000
hi Pmenu                guibg=#e38081 guifg=#ffffff
hi PmenuSel             guibg=#3D4646 guifg=#ffffff
hi NonText              guibg=bg guifg=#e29aeb

" General Syntax Colors

" Light green
hi Comment              gui=NONE guifg=#C8F482 guibg=bg

" Green
hi Identifier           gui=NONE guifg=#82c057 guibg=bg
hi Type                 gui=NONE guifg=#82c057 guibg=bg
hi Function             gui=NONE guifg=#82c057 guibg=bg

" Yellow
hi Statement            gui=NONE guifg=#F6DA7B guibg=bg
hi Conditional          gui=NONE guifg=#F6DA7B guibg=bg
hi Operator             gui=NONE guifg=#F6DA7B guibg=bg
hi Label                gui=NONE guifg=#F6DA7B guibg=bg
hi Define               gui=NONE guifg=#F6DA7B guibg=bg
hi Macro                gui=NONE guifg=#F6DA7B guibg=bg

" Rose
hi String               gui=NONE guifg=#E38081 guibg=bg

" Pink
hi Todo                 gui=bold guifg=#e29aeb guibg=bg

" Light Purple
hi Character            gui=NONE guifg=#9d7ff2 guibg=bg

" Dark Purple
hi Number               gui=NONE guifg=#776CC4 guibg=bg
hi Float                gui=NONE guifg=#776CC4 guibg=bg
hi Boolean              gui=bold guifg=#776CC4 guibg=bg

" Cyan
hi StorageClass         gui=NONE guifg=#95D5F1 guibg=bg
hi Structure            gui=NONE guifg=#95D5F1 guibg=bg
hi Typedef              gui=NONE guifg=#95D5F1 guibg=bg
hi Constant             gui=NONE guifg=#95D5F1 guibg=bg

" Blue #9bb2ee

" Dunno color
hi Special              gui=NONE guifg=#55747c guibg=bg
hi Delimiter            gui=NONE guifg=#55747c guibg=bg
hi SpecialChar          gui=NONE guifg=#55747c guibg=bg
hi SpecialComment       gui=NONE guifg=#55747c guibg=bg
hi Tag                  gui=NONE guifg=#55747c guibg=bg
hi Debug                gui=NONE guifg=#55747c guibg=bg

" Brown
hi Repeat               gui=NONE guifg=#C67C48 guibg=bg
hi PreProc              gui=NONE guifg=#C67C48 guibg=bg
hi Include              gui=NONE guifg=#C67C48 guibg=bg
hi PreCondit            gui=NONE guifg=#C67C48 guibg=bg
hi Keyword              gui=NONE guifg=#C67C48 guibg=bg
hi Exception            gui=NONE guifg=#C67C48 guibg=bg

" Other
hi Underlined           gui=underline guifg=#C8F482 guibg=bg
hi Ignore               guifg=#55747c
hi Error                guifg=#FFFF99  guibg=#FF0000

" Ruby-specific
hi rubySharpBang        gui=bold guifg=#e29aeb
hi rubyRegexp           guifg=#9BB2EE
