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
    },
  },
}
