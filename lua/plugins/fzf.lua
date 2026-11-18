return {
  { 'junegunn/fzf.vim' },
  { 'junegunn/fzf', build = function() vim.fn['fzf#install']() end },
}
