local filetypes = { 'css', 'sass', 'scss', 'less' }

return {
  {
    'brenoprata10/nvim-highlight-colors',
    event = {
      { event = { 'BufReadPre', 'BufNewFile' }, pattern = { '*.css', '*.sass', '*.scss', '*.less' } },
    },
    opts = {
      -- Once loaded, the plugin colors every buffer, so it skips buffers of other filetypes.
      exclude_buffer = function(bufnr) return not vim.tbl_contains(filetypes, vim.bo[bufnr].filetype) end,
    },
  },
}
