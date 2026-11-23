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

-- Puts lines in the buffer, opens a line below them and types text. Returns when the completion menu shows every label
-- in labels. The sources answer one by one, and a late answer can reset a selection, so a key that needs the menu waits
-- for all of them.
local function type_with_menu(lines, text, labels)
  type_keys('<Esc>')
  wait_for_mode('n')
  call('vim.api.nvim_buf_set_lines(0, 0, -1, false, ...)', lines)
  type_keys('Go' .. text)
  local shown = wait_for(function()
    return call([[
      local cmp, found = require('blink.cmp'), {}
      for _, item in ipairs(cmp.get_items()) do
        found[item.label] = true
      end
      return cmp.is_menu_visible() and vim.iter({ ... }):all(function(label) return found[label] end)
    ]], unpack(labels))
  end, true, 10000)
  assert(shown, ('the completion menu did not show %s after typing %s'):format(table.concat(labels, ', '), text))
end

-- Returns the label of the selected item when the menu shows and the line shows the label, or ''.
local shown_selection = [[
  local cmp = require('blink.cmp')
  local item, line = cmp.get_selected_item(), vim.api.nvim_get_current_line()
  return cmp.is_menu_visible() and item and item.label == line and line or ''
]]

-- Selects the next item of the menu. Returns its label when the selection still shows 100 ms later, or ''.
local function select_next()
  local before = call('return vim.api.nvim_get_current_line()')
  type_keys('<C-n>')
  local label = ''
  if not vim.wait(3000, function()
    label = call(shown_selection)
    return label ~= '' and label ~= before
  end, 20) then
    return ''
  end
  vim.wait(100)
  return call(shown_selection) == label and label or ''
end

-- Under load, blink.cmp can close the menu after <C-n> puts the item in the line, because it then takes that change
-- for typing. So the setup of the next check tries up to 3 times to get a selection that holds.
local selected = ''
for _ = 1, 3 do
  type_with_menu({ 'foobar foobaz' }, 'foo', { 'foobar', 'foobaz' })
  selected = select_next()
  if selected ~= '' then
    break
  end
end
local accepted_with_enter = result_of('<CR>')

type_with_menu({ 'foobar foobaz' }, 'def foo', {})
local enter_without_selection = result_of('<CR>')

type_with_menu({ 'foobar' }, 'foo', { 'foobar' })
local accepted_with_ctrl_y = result_of('<C-y>')

type_with_menu({ '' }, 'def', { 'def' })
call([[
  local cmp = require('blink.cmp')
  for index, item in ipairs(cmp.get_items()) do
    if item.source_id == 'snippets' and item.label == 'def' then
      return cmp.accept({ index = index })
    end
  end
]])
wait_for_mode('s')
type_keys('<Tab>')
wait_for_mode('i')
type_keys('x')
local jumped = wait_for(buffer_lines, { '', 'def method_name', '  x', 'end' })

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
type_keys('ototal')
local before_paren = wait_for(signature_visible, false)
type_keys('(')
local shown_on_paren = { before_paren, wait_for(signature_visible, true) }

type_keys('<Esc>')
wait_for_mode('n')
-- Returns whether the menu of blink.cmp shows, and whether its items hold the echo command.
local function cmdline_menu()
  return call([[
    local cmp = require('blink.cmp')
    local labels = vim.tbl_map(function(item) return item.label end, cmp.get_items())
    return { visible = cmp.is_menu_visible(), echo = vim.tbl_contains(labels, 'echo') }
  ]])
end
type_keys(':ech')
local menu_while_typing = wait_for(cmdline_menu, { visible = true, echo = true })
type_keys('<Tab>')
local completed_with_tab = wait_for(function()
  return call("local item = require('blink.cmp').get_selected_item() return { vim.fn.getcmdline(), item and item.label }")
end, { 'echo', 'echo' })
type_keys('<Esc>')
wait_for_mode('n')
type_keys(':let g:typed = 1<CR>')
local ran_with_enter = wait_for(function() return call('return vim.g.typed') end, 1)
type_keys(':le')
wait_for(function() return call("return require('blink.cmp').is_menu_visible()") end, true)
type_keys('<Up>')
local recalled_with_up = wait_for(function() return call('return vim.fn.getcmdline()') end, 'let g:typed = 1')
type_keys('<Esc>')
wait_for_mode('n')

vim.fn.jobstop(job)

equals(
  '<CR> accepts the selected item of the completion menu',
  accepted_with_enter,
  { lines = { 'foobar foobaz', selected }, accepted = true }
)
equals(
  '<CR> with no selected item starts a new line, and vim-endwise closes the ruby def',
  enter_without_selection,
  { lines = { 'foobar foobaz', 'def foo', '  ', 'end' }, accepted = false }
)
equals('<C-y> accepts the first item of the completion menu', accepted_with_ctrl_y, { lines = { 'foobar', 'foobar' }, accepted = true })
equals('<Tab> jumps to the next field of a snippet from friendly-snippets', jumped, { '', 'def method_name', '  x', 'end' })
equals('<C-k> enters a digraph in a buffer with no language server', digraph, { 'ë' })
equals('<C-k> in insert mode shows the signature of the function', shown_with_ctrl_k, true)
equals('<C-k> hides the signature that shows', hidden_with_ctrl_k, false)
equals('typing ( shows the signature by itself', shown_on_paren, { false, true })
equals('typing on the command line opens the menu of blink.cmp, with the matching commands', menu_while_typing, { visible = true, echo = true })
equals('<Tab> on the command line completes the command with the first item of the menu', completed_with_tab, { 'echo', 'echo' })
equals('<CR> on the command line with no selected item runs the typed command', ran_with_enter, 1)
equals('<Up> on the command line with the menu open recalls the last command', recalled_with_up, 'let g:typed = 1')

report.finish()
