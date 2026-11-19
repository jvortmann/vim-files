local prettier_filetypes = {
  'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'css', 'less', 'scss', 'json', 'graphql',
  'markdown', 'vue', 'yaml', 'html', 'ruby',
}

local formatters_by_ft = {}
for _, filetype in ipairs(prettier_filetypes) do
  formatters_by_ft[filetype] = { 'prettier' }
end

local function ruby_plugin_found(ctx)
  for dir in vim.fs.parents(ctx.filename) do
    if vim.fn.isdirectory(dir .. '/node_modules/@prettier/plugin-ruby') == 1 then
      return true
    end
  end
  return false
end

local function prettier_can_run(_, ctx)
  local filetypes = vim.split(vim.bo[ctx.buf].filetype, '.', { plain = true })
  return not vim.tbl_contains(filetypes, 'ruby') or ruby_plugin_found(ctx)
end

local function format_on_save(bufnr)
  local formatters, lsp = require('conform').list_formatters_to_run(bufnr)
  if #formatters == 0 and not lsp then
    return nil
  end
  for _, formatter in ipairs(formatters) do
    if formatter.name == 'prettier' and not formatter.cwd then
      return nil
    end
  end
  return { timeout_ms = 2000 }
end

return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    keys = {
      {
        '<leader>p',
        function() require('conform').format({ async = true }) end,
        mode = { 'n', 'x' },
        desc = 'Format the buffer or the selection',
      },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      default_format_opts = { lsp_format = 'fallback' },
      formatters = {
        prettier = { condition = prettier_can_run },
      },
      format_on_save = format_on_save,
    },
  },
}
