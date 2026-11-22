-- Run: nvim -i NONE --headless -c 'luafile tests/lsp_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local mason = dofile(tests_dir .. '/support/mason.lua')
local lsp_server = dofile(tests_dir .. '/support/lsp_server.lua')
local equals = report.equals

-- No server is installed during the suite, so each opened file logs an error about a missing command.
-- The test keeps those errors out of the LSP log of the user.
vim.lsp.log.set_level(vim.log.levels.OFF)

local function new_folder()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir, 'p')
  return dir
end

-- Opens the file name in a new folder, and returns the names of the enabled servers for its filetype.
local function servers_for(name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(new_folder() .. '/' .. name))
  local names = vim.tbl_map(function(config) return config.name end, vim.lsp.get_configs({ enabled = true, filetype = vim.bo.filetype }))
  table.sort(names)
  vim.cmd('silent bwipeout!')
  return names
end

for name, expected in vim.spairs({
  ['app.ts'] = { 'eslint', 'vtsls' },
  ['app.tsx'] = { 'eslint', 'vtsls' },
  ['app.js'] = { 'eslint', 'vtsls' },
  ['app.jsx'] = { 'eslint', 'vtsls' },
  ['order.rb'] = { 'ruby_lsp' },
  ['order_spec.rb'] = { 'ruby_lsp' },
  ['init.lua'] = { 'lua_ls' },
  ['main.go'] = { 'gopls' },
  ['main.zig'] = { 'zls' },
  ['main.rs'] = { 'rust_analyzer' },
}) do
  equals('a buffer of ' .. name .. ' has the servers ' .. table.concat(expected, ' and '), servers_for(name), expected)
end

for _, name in ipairs({ 'lua_ls', 'vtsls' }) do
  vim.lsp.config(name, { cmd = lsp_server.cmd({ initialize = { capabilities = {} } }) })
end

-- Opens the file name in the folder, and returns the number of servers that attach to it.
local function servers_attached(dir, name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(dir .. '/' .. name))
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(500, function() return #vim.lsp.get_clients({ bufnr = buf }) > 0 end)
  return #vim.lsp.get_clients({ bufnr = buf })
end

local project = new_folder()
vim.fn.mkdir(project .. '/.git')
equals('a lua file in a folder with .git starts lua_ls', servers_attached(project, 'init.lua'), 1)
equals('a lua file in a folder with no project marker starts no server', servers_attached(new_folder(), 'init.lua'), 0)
equals('a typescript file in a folder with no project marker starts no server', servers_attached(new_folder(), 'app.ts'), 0)

local lua = vim.lsp.config.lua_ls.settings.Lua
equals(
  'lua_ls knows the vim global and the runtime of Neovim',
  { version = vim.tbl_get(lua, 'runtime', 'version'), library = vim.tbl_get(lua, 'workspace', 'library'), globals = vim.tbl_get(lua, 'diagnostics', 'globals') },
  { version = 'LuaJIT', library = { vim.env.VIMRUNTIME }, globals = { 'vim' } }
)

local lsp_keys = {
  'n K', 'n gd', 'n grn', 'n gra', 'x gra', 'n grr', 'n gri', 'n gO', 'n [d', 'n ]d', 'i <C-S>', 's <C-S>', 'n \\d', 'n \\D',
}

-- Returns the entries of lsp_keys that have no map with a description in the current buffer only.
local function missing_buffer_keys()
  return vim.tbl_filter(function(entry)
    local mode, lhs = entry:match('^(%S+) (.+)$')
    local map = vim.fn.maparg(lhs, mode, false, true)
    return map.buffer ~= 1 or type(map.desc) ~= 'string' or map.desc == ''
  end, lsp_keys)
end

servers_attached(project, 'init.lua')
equals('a buffer with a server has each LSP key, with a description, for that buffer only', missing_buffer_keys(), {})
vim.cmd('silent edit ' .. vim.fn.fnameescape(project .. '/notes.txt'))
equals('a buffer with no server has no LSP key of its own', #missing_buffer_keys(), #lsp_keys)
local k = vim.fn.maparg('K', 'n', false, true)
equals('K in a buffer with no server still does nothing', { rhs = k.rhs, buffer = k.buffer }, { rhs = '<nop>', buffer = 0 })

local pane = screen.start({ args = { '--cmd', "let g:fake_mason_installed = ['gopls']" } })
local calls
vim.wait(5000, function()
  calls = pane.run(mason.calls)
  return #calls >= 7
end)
pane.stop()
equals('an editor with a screen installs each missing server at start', calls, {
  'refresh', 'install eslint-lsp', 'install lua-language-server', 'install ruby-lsp', 'install rust-analyzer',
  'install vtsls', 'install zls',
})

local editor, job = child.start()
vim.wait(1000)
calls = vim.rpcrequest(editor, 'nvim_exec_lua', mason.calls, {})
vim.fn.jobstop(job)
equals('a headless editor installs nothing and reads no registry', calls, {})

local diagnostics_folder = new_folder()
vim.fn.writefile({ 'one', 'two', 'three' }, diagnostics_folder .. '/file.txt')
pane = screen.start({ cwd = diagnostics_folder, args = { 'file.txt' }, width = 60 })
pane.run([[
  local server = dofile(...)
  local function at(line, message)
    return { range = { start = { line = line, character = 0 }, ['end'] = { line = line, character = 1 } }, severity = 1, message = message }
  end
  local diagnostics = { at(0, 'first problem'), at(2, 'third problem') }
  vim.lsp.start({ name = 'fake', root_dir = vim.fn.getcwd(), cmd = server.cmd({ initialize = { capabilities = { textDocumentSync = 1 } } }, diagnostics) })
]], tests_dir .. '/support/lsp_server.lua')

-- Waits until the rows of the pane that start with the numbers of lines 1 and 3 equal expected, and returns them.
local function diagnostic_rows(expected)
  local found
  vim.wait(5000, function()
    found = {}
    for _, row in ipairs(pane.rows()) do
      local number = row:match('^.%s+(%d) ')
      if number == '1' or number == '3' then
        found[number] = row:find('problem', 1, true) and row:match('%a+ problem') or 'no message'
      end
    end
    return vim.deep_equal(found, expected)
  end)
  return found
end

local on_first = diagnostic_rows({ ['1'] = 'first problem', ['3'] = 'no message' })
equals('the cursor line shows the message of its diagnostic', on_first['1'], 'first problem')
equals('another line with a diagnostic shows no message', on_first['3'], 'no message')
pane.run([[vim.api.nvim_win_set_cursor(0, { 3, 0 })]])
equals(
  'moving the cursor moves the message to the new line',
  diagnostic_rows({ ['1'] = 'no message', ['3'] = 'third problem' }),
  { ['1'] = 'no message', ['3'] = 'third problem' }
)
pane.stop()

-- Opens the file name in the folder, attaches a fake server with a warning on line 1 and an error on line 3, and waits for them.
local function open_with_diagnostics(dir, name)
  vim.fn.writefile({ 'one', 'two', 'three' }, dir .. '/' .. name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(dir .. '/' .. name))
  local function at(line, severity, message)
    return { range = { start = { line = line, character = 0 }, ['end'] = { line = line, character = 1 } }, severity = severity, message = message }
  end
  vim.lsp.start({
    name = 'diagnostics-server',
    root_dir = dir,
    cmd = lsp_server.cmd({ initialize = { capabilities = { textDocumentSync = 1 } } }, { at(0, 2, 'a warning'), at(2, 1, 'an error') }),
  })
  vim.wait(2000, function() return #vim.diagnostic.get(0) == 2 end)
end

-- Returns the file name, line, type and text of each item of a list.
local function entries(items)
  return vim.tbl_map(function(item)
    return { vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item.bufnr), ':t'), item.lnum, item.type, item.text }
  end, items)
end

local list_folder = new_folder()
open_with_diagnostics(list_folder, 'a.txt')
local file_window = vim.api.nvim_get_current_win()
vim.api.nvim_feedkeys('\\d', 'mx', false)
local loclist = vim.fn.getloclist(file_window, { title = 1, items = 1 })
equals('\\d lists the diagnostics of the buffer in the location list, errors first, and opens it', {
  title = loclist.title,
  items = entries(loclist.items),
  open = vim.fn.getloclist(file_window, { winid = 1 }).winid ~= 0,
}, {
  title = 'Diagnostics',
  items = { { 'a.txt', 3, 'E', 'an error' }, { 'a.txt', 1, 'W', 'a warning' } },
  open = true,
})
vim.cmd('lclose')

open_with_diagnostics(list_folder, 'b.txt')
vim.api.nvim_feedkeys('\\D', 'mx', false)
local qflist = vim.fn.getqflist({ title = 1, items = 1 })
equals('\\D lists the diagnostics of every buffer in the quickfix list, errors first, and opens it', {
  title = qflist.title,
  items = entries(qflist.items),
  open = vim.fn.getqflist({ winid = 1 }).winid ~= 0,
}, {
  title = 'Diagnostics of all buffers',
  items = {
    { 'a.txt', 3, 'E', 'an error' }, { 'b.txt', 3, 'E', 'an error' },
    { 'a.txt', 1, 'W', 'a warning' }, { 'b.txt', 1, 'W', 'a warning' },
  },
  open = true,
})
vim.cmd('cclose')

vim.cmd('silent edit ' .. vim.fn.fnameescape(list_folder .. '/a.txt'))
vim.diagnostic.set(vim.api.nvim_create_namespace('lsp_test_linter'), 0, {
  { lnum = 1, col = 0, severity = vim.diagnostic.severity.INFO, message = 'from a linter' },
})
file_window = vim.api.nvim_get_current_win()
vim.api.nvim_feedkeys('\\d', 'mx', false)
equals(
  '\\d also lists a diagnostic that comes from no language server',
  entries(vim.fn.getloclist(file_window)),
  { { 'a.txt', 3, 'E', 'an error' }, { 'a.txt', 1, 'W', 'a warning' }, { 'a.txt', 2, 'I', 'from a linter' } }
)
vim.cmd('lclose')

report.finish()
