return {
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = {
      'NvimTreeOpen', 'NvimTreeClose', 'NvimTreeToggle', 'NvimTreeFocus', 'NvimTreeRefresh', 'NvimTreeClipboard',
      'NvimTreeFindFile', 'NvimTreeFindFileToggle', 'NvimTreeResize', 'NvimTreeCollapse',
      'NvimTreeCollapseKeepBuffers', 'NvimTreeHiTest',
    },
    keys = {
      { '<F2>', '<cmd>NvimTreeToggle<CR>', mode = { 'n', 'x', 's', 'o' }, silent = true, desc = 'Toggle the file tree' },
    },
    opts = {
      -- Folders stay with netrw, so `:e .` opens netrw.
      disable_netrw = false,
      hijack_netrw = false,
      -- The sign column shows only when a line has a sign, so the tree has no blank sign cell,
      -- like the other side windows.
      view = { signcolumn = 'auto' },
      -- The tree lists the whole folder, with the files that git ignores.
      filters = { git_ignored = false },
      -- A file opens in the last window, with no prompt to pick a window.
      actions = { open_file = { window_picker = { enable = false } } },
      -- The tree keeps every default key and adds <C-s>, which opens the file in a horizontal split as <C-x> does.
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set('n', '<C-s>', api.node.open.horizontal, {
          buffer = bufnr,
          desc = 'nvim-tree: Open: Horizontal Split',
          noremap = true,
          silent = true,
          nowait = true,
        })
      end,
    },
  },
}
