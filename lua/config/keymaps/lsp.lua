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
