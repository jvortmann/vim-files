local nvo = { 'n', 'x', 's', 'o' }

return {
  {
    'majutsushi/tagbar',
    cmd = { 'Tagbar', 'TagbarOpenAutoClose' },
    keys = {
      { '<M-i>', ':TagbarOpenAutoClose<CR>', mode = nvo, silent = true, desc = 'Open tagbar, close it after a jump' },
      { '<leader>ii', ':TagbarOpenAutoClose<CR>', mode = nvo, silent = true, desc = 'Open tagbar, close it after a jump' },
      { '<M-S-i>', ':Tagbar<CR>', mode = nvo, silent = true, desc = 'Toggle tagbar' },
      { '<leader>i', ':Tagbar<CR>', mode = nvo, silent = true, desc = 'Toggle tagbar' },
      { '<leader>i<space>', ':Tagbar<CR>', mode = nvo, silent = true, desc = 'Toggle tagbar' },
    },
    init = function()
      -- configuring tagbar
      vim.g.tagbar_width = 60

      vim.g.tagbar_type_elixir = {
        ctagstype = 'elixir',
        kinds = {
          'f:functions',
          'functions:functions',
          'c:callbacks',
          'd:delegates',
          'e:exceptions',
          'i:implementations',
          'a:macros',
          'o:operators',
          'm:modules',
          'p:protocols',
          'r:records',
        },
      }

      vim.g.tagbar_type_go = {
        ctagstype = 'go',
        kinds = {
          'p:package',
          'f:function',
          'v:variables',
          't:type',
          'c:const',
        },
      }

      vim.g.tagbar_type_ruby = {
        kinds = {
          'm:modules',
          'c:classes',
          'd:describes',
          'C:contexts',
          'f:methods',
          'F:singleton methods',
        },
      }

      vim.g.tagbar_type_rust = {
        ctagstype = 'rust',
        kinds = {
          'T:types,type definitions',
          'f:functions,function definitions',
          'g:enum,enumeration names',
          's:structure names',
          'm:modules,module names',
          'c:consts,static constants',
          't:traits,traits',
          'i:impls,trait implementations',
        },
      }

      vim.g.tagbar_type_scala = {
        ctagstype = 'scala',
        sro = '.',
        kinds = {
          'p:packages',
          'T:types:1',
          't:traits',
          'o:objects',
          'O:case objects',
          'c:classes',
          'C:case classes',
          'm:methods',
          'V:values:1',
          'v:variables:1',
        },
      }
    end,
  },
}
