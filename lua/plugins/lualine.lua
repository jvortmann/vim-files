return {
  {
    'nvim-lualine/lualine.nvim',
    config = function()
      local parts = require('config.statusline_parts')
      parts.setup()
      local file_name = { 'filename', path = 1, symbols = { readonly = '[RO]' } }
      local percent = '%p%%:%L'
      local position = '%l:%v'
      require('lualine').setup({
        options = {
          icons_enabled = false,
          component_separators = '',
          section_separators = '',
          -- A function, so lualine runs it again on ColorScheme and on a change of background.
          -- solarized8 gets the solarized theme. Any other colorscheme gets its colors from its highlight groups.
          theme = function()
            return vim.g.colors_name == 'solarized8' and 'solarized' or 'auto'
          end,
        },
        sections = {
          lualine_a = { 'mode', parts.spell },
          lualine_b = { { 'diagnostics', sources = { 'nvim_diagnostic' }, sections = { 'error', 'warn' } }, parts.whitespace },
          lualine_c = { file_name },
          lualine_x = { 'searchcount', parts.words, 'filetype' },
          lualine_y = { parts.encoding, percent },
          lualine_z = { position },
        },
        inactive_sections = {
          lualine_c = { file_name },
          lualine_x = { percent, position },
        },
        extensions = { 'quickfix' },
      })
    end,
  },
}
