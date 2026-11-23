-- Run: tests/run.sh tests/blink-cmp_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local lsp_server = dofile(tests_dir .. '/support/lsp_server.lua')
local equals = report.equals

vim.lsp.log.set_level(vim.log.levels.OFF)
vim.lsp.config('lua_ls', { cmd = lsp_server.cmd({ initialize = { capabilities = {} } }) })
local project = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(project .. '/.git', 'p')
vim.cmd('silent edit ' .. vim.fn.fnameescape(project .. '/init.lua'))
vim.wait(2000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end)
local client = vim.lsp.get_clients({ bufnr = 0 })[1]
local function completion_item(capabilities)
  local item = vim.tbl_get(capabilities or {}, 'textDocument', 'completion', 'completionItem') or {}
  return { snippetSupport = item.snippetSupport, resolve = vim.tbl_get(item, 'resolveSupport', 'properties') }
end
equals(
  'a language server gets the completion capabilities of blink.cmp, with snippet support',
  completion_item(client and client.capabilities),
  completion_item(require('blink.cmp').get_lsp_capabilities())
)

local folder = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(folder, 'p')
local editor, job = child.start({ cwd = folder, files = { 'order.rb' } })

local function call(code, ...)
  return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
end

local function type_keys(keys)
  vim.rpcrequest(editor, 'nvim_input', keys)
end

-- Waits until get returns expected, for up to timeout milliseconds (3000 by default). Returns the last value of get.
local function wait_for(get, expected, timeout)
  local got
  vim.wait(timeout or 3000, function()
    got = get()
    return vim.deep_equal(got, expected)
  end, 20)
  return got
end

local function wait_for_mode(mode)
  wait_for(function() return call('return vim.api.nvim_get_mode().mode') end, mode)
end

local function buffer_lines()
  return call('return vim.api.nvim_buf_get_lines(0, 0, -1, false)')
end

call([[vim.api.nvim_create_autocmd('User', { pattern = 'BlinkCmpAccept', callback = function() vim.g.accepted = true end })]])

-- Types keys, and waits until blink.cmp accepts an item or the number of lines changes.
-- Returns the lines of the buffer and whether blink.cmp accepted an item.
local function result_of(keys)
  local count = call('vim.g.accepted = false return vim.api.nvim_buf_line_count(0)')
  type_keys(keys)
  local got
  vim.wait(3000, function()
    got = call('return { lines = vim.api.nvim_buf_get_lines(0, 0, -1, false), accepted = vim.g.accepted }')
    return got.accepted or #got.lines ~= count
  end, 20)
  return got
end

-- Puts lines in the buffer, opens a line below them and types text. Returns when the completion menu shows.
local function type_with_menu(lines, text)
  type_keys('<Esc>')
  wait_for_mode('n')
  call('vim.api.nvim_buf_set_lines(0, 0, -1, false, ...)', lines)
  type_keys('Go' .. text)
  local shown = wait_for(function() return call("return require('blink.cmp').is_menu_visible()") end, true, 10000)
  assert(shown, 'the completion menu did not show after typing ' .. text)
end

type_with_menu({ 'foobar foobaz' }, 'def foo')
local enter_without_selection = result_of('<CR>')

type_keys('<Esc>')
wait_for_mode('n')
call('vim.api.nvim_buf_set_lines(0, 0, -1, false, { "" })')
type_keys('i<C-k>e:')
local digraph = wait_for(buffer_lines, { 'ë' })

type_keys('<Esc>')
wait_for_mode('n')
call([[
  local server = dofile(...)
  vim.cmd('enew')
  vim.lsp.start({
    name = 'signature_server',
    root_dir = vim.fn.getcwd(),
    cmd = server.cmd({
      initialize = { capabilities = { signatureHelpProvider = { triggerCharacters = { '(', ',' } } } },
      ['textDocument/signatureHelp'] = { signatures = { { label = 'total(price, tax)' } } },
    }),
  })
]], tests_dir .. '/support/lsp_server.lua')
wait_for(function() return call('return #vim.lsp.get_clients({ bufnr = 0 })') end, 1)
-- Returns 'blocked' while the child waits for the rest of a key, such as the digraph of <C-k>.
-- A request then blocks, and nvim_get_mode is the one that answers.
local function signature_visible()
  if vim.rpcrequest(editor, 'nvim_get_mode').blocking then
    return 'blocked'
  end
  return call("return require('blink.cmp').is_signature_visible()")
end
type_keys('i<C-k>')
local shown_with_ctrl_k = wait_for(signature_visible, true)
type_keys('<C-k>')
local hidden_with_ctrl_k = wait_for(signature_visible, false)

type_keys('<Esc>')
wait_for_mode('n')
type_keys(':let g:typed = 1<CR>')
local ran_with_enter = wait_for(function() return call('return vim.g.typed') end, 1)

vim.fn.jobstop(job)

equals(
  '<CR> with no selected item starts a new line, and vim-endwise closes the ruby def',
  enter_without_selection,
  { lines = { 'foobar foobaz', 'def foo', '  ', 'end' }, accepted = false }
)
equals('<C-k> enters a digraph in a buffer with no language server', digraph, { 'ë' })
equals('<C-k> in insert mode shows the signature of the function', shown_with_ctrl_k, true)
equals('<C-k> hides the signature that shows', hidden_with_ctrl_k, false)
equals('<CR> on the command line with no selected item runs the typed command', ran_with_enter, 1)

report.finish()
