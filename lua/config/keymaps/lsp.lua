local list_diagnostics

-- Neovim maps most of these keys for every buffer. These maps exist only in a buffer with a language server, and they add a description.
local keys = {
  { 'n', 'K', vim.lsp.buf.hover, 'Show the documentation of the symbol' },
  { 'n', 'gd', vim.lsp.buf.definition, 'Go to the definition of the symbol' },
  { 'n', 'grn', vim.lsp.buf.rename, 'Rename the symbol' },
  { { 'n', 'x' }, 'gra', vim.lsp.buf.code_action, 'Show the code actions' },
  { 'n', 'grr', vim.lsp.buf.references, 'List the references to the symbol' },
  { 'n', 'gri', vim.lsp.buf.implementation, 'List the implementations of the symbol' },
  { 'n', 'gO', vim.lsp.buf.document_symbol, 'List the symbols of the buffer' },
  { 'n', ']d', function() vim.diagnostic.jump({ count = vim.v.count1 }) end, 'Go to the next diagnostic' },
  { 'n', '[d', function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, 'Go to the previous diagnostic' },
  { { 'i', 's' }, '<C-S>', vim.lsp.buf.signature_help, 'Show the signature of the function' },
  { 'n', '<leader>d', function() list_diagnostics(true) end, 'List the diagnostics of the buffer' },
  { 'n', '<leader>D', function() list_diagnostics(false) end, 'List the diagnostics of all buffers' },
}

local group = vim.api.nvim_create_augroup('LspKeys', { clear = true })

vim.api.nvim_create_autocmd('LspAttach', {
  group = group,
  callback = function(args)
    for _, key in ipairs(keys) do
      vim.keymap.set(key[1], key[2], key[3], { buf = args.buf, desc = key[4] })
    end
  end,
})

-- When the last server of the buffer stops, the keys go. The global maps apply again, so K does nothing.
vim.api.nvim_create_autocmd('LspDetach', {
  group = group,
  callback = function(args)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
      if client.id ~= args.data.client_id then
        return
      end
    end
    for _, key in ipairs(keys) do
      -- Neovim can delete K first, so a missing map is not an error.
      pcall(vim.keymap.del, key[1], key[2], { buf = args.buf })
    end
  end,
})

local severity_order = { E = 1, W = 2, I = 3, N = 4 }

-- Fills the location list with the diagnostics of the buffer, or the quickfix list with those of every buffer, and opens it.
-- The list holds every source of diagnostics. Neovim's own list sorts only by buffer and line, so this one puts errors first.
function list_diagnostics(buffer_only)
  local items = vim.diagnostic.toqflist(vim.diagnostic.get(buffer_only and 0 or nil))
  table.sort(items, function(a, b)
    if a.type ~= b.type then
      return (severity_order[a.type] or 5) < (severity_order[b.type] or 5)
    end
    if a.bufnr ~= b.bufnr then
      return a.bufnr < b.bufnr
    end
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    return a.col < b.col
  end)
  if buffer_only then
    vim.fn.setloclist(0, {}, ' ', { title = 'Diagnostics', items = items })
    vim.cmd('lopen')
  else
    vim.fn.setqflist({}, ' ', { title = 'Diagnostics of all buffers', items = items })
    vim.cmd('copen')
  end
end
