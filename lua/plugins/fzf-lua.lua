local nvo = { 'n', 'x', 's', 'o' }

return {
  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'FzfLua',
    keys = {
      { '<leader>ff', '<cmd>FzfLua files<CR>', mode = nvo, silent = true, desc = 'Find files' },
      { '<leader>f', '<cmd>FzfLua files<CR>', mode = nvo, silent = true, desc = 'Find files (fallback)' },
      { '<leader>fl', '<cmd>FzfLua blines<CR>', mode = nvo, silent = true, desc = 'Find lines in current buffer' },
      { '<leader>fla', '<cmd>FzfLua lines<CR>', mode = nvo, silent = true, desc = 'Find lines in open buffers' },
      { '<leader>fm', '<cmd>FzfLua marks<CR>', mode = nvo, silent = true, desc = 'Find marks' },
      { '<leader>fo', '<cmd>FzfLua buffers<CR>', mode = nvo, silent = true, desc = 'Find open buffers' },
      { '<leader>o', '<cmd>FzfLua buffers<CR>', mode = nvo, silent = true, desc = 'Find open buffers (fallback)' },
      { '<leader>ft', '<cmd>FzfLua btags<CR>', mode = nvo, silent = true, desc = 'Find tags on current buffer' },
      { '<leader>fta', '<cmd>FzfLua tags<CR>', mode = nvo, silent = true, desc = 'Find tags' },
      { '<leader>fh', '<cmd>FzfLua history<CR>', mode = nvo, silent = true, desc = 'Find files history' },
      { '<leader>fg', '<cmd>FzfLua live_grep<CR>', mode = nvo, silent = true, desc = 'Grep the files' },
      { '<leader>fw', '<cmd>FzfLua grep_cword<CR>', mode = nvo, silent = true, desc = 'Grep the word under the cursor' },
    },
    init = function()
      -- fzf-lua reads g:fzf_history_dir, the setting that fzf.vim used.
      -- Each picker keeps its queries in its own file in that folder.
      vim.g.fzf_history_dir = '~/.config/fzf/fzf-history'
    end,
    opts = function()
      local defaults = require('fzf-lua.defaults').defaults
      return {
        winopts = { width = 0.9, height = 0.6 },
        hls = {
          normal = 'NormalFloat',
          border = 'FloatBorder',
          title = 'FloatBorder',
          preview_normal = 'NormalFloat',
          preview_border = 'FloatBorder',
          preview_title = 'FloatBorder',
        },
        files = {
          fd_opts = '--exclude node_modules ' .. defaults.files.fd_opts,
          rg_opts = "-g '!node_modules' " .. defaults.files.rg_opts,
        },
        grep = { rg_opts = "-g '!node_modules' " .. defaults.grep.rg_opts },
      }
    end,
  },
}
