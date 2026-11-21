-- Neovim maps most of these keys for every buffer. These maps exist only in a buffer with a language server, and they add a description.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('LspKeys', { clear = true }),
  callback = function(args)
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buf = args.buf, desc = desc })
    end

    map('n', 'K', vim.lsp.buf.hover, 'Show the documentation of the symbol')
    map('n', 'gd', vim.lsp.buf.definition, 'Go to the definition of the symbol')
    map('n', 'grn', vim.lsp.buf.rename, 'Rename the symbol')
    map({ 'n', 'x' }, 'gra', vim.lsp.buf.code_action, 'Show the code actions')
    map('n', 'grr', vim.lsp.buf.references, 'List the references to the symbol')
    map('n', 'gri', vim.lsp.buf.implementation, 'List the implementations of the symbol')
    map('n', 'gO', vim.lsp.buf.document_symbol, 'List the symbols of the buffer')
    map('n', ']d', function() vim.diagnostic.jump({ count = vim.v.count1 }) end, 'Go to the next diagnostic')
    map('n', '[d', function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, 'Go to the previous diagnostic')
    map({ 'i', 's' }, '<C-S>', vim.lsp.buf.signature_help, 'Show the signature of the function')
  end,
})
