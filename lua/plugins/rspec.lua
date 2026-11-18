return {
  { -- [SLOW] ruby rspec
    'keith/rspec.vim',
    ft = 'ruby',
    -- lazy.nvim sources ftdetect but not after/ftdetect, where rspec.vim keeps its detection.
    -- An init runs at startup, so the detection works before the plugin loads.
    init = function(plugin)
      vim.cmd('augroup filetypedetect')
      vim.cmd.source(plugin.dir .. '/after/ftdetect/rspec.vim')
      vim.cmd('augroup END')
    end,
  },
}
