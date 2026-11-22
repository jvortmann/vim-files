-- Run: tests/run.sh tests/lsp_idle_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local equals = report.equals

-- Starts a child with an idle limit of 300 ms in a new project with a.txt and b.txt.
-- The child enables the fake server for text files and opens a.txt. It returns run(code, ...) and the job.
-- With initialize_ms, the server answers the initialize request after that many milliseconds.
local function start(initialize_ms)
  local project = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(project .. '/.git', 'p')
  for _, name in ipairs({ 'a.txt', 'b.txt' }) do
    vim.fn.writefile({ 'one', 'two', 'three' }, project .. '/' .. name)
  end
  local editor, job = child.start({ cwd = project, args = { '--cmd', 'let g:lsp_idle_ms = 300 | let g:lsp_idle_check_ms = 50' } })
  local function run(code, ...)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
  end
  run([[
    local server, initialize_ms = ...
    server = dofile(server)
    local cmd = server.cmd({ initialize = { capabilities = { textDocumentSync = 1 } } }, {
        { range = { start = { line = 0, character = 0 }, ['end'] = { line = 0, character = 1 } }, severity = 1, message = 'bad' },
      })
    vim.lsp.config('fake', {
      cmd = function(dispatchers)
        local rpc = cmd(dispatchers)
        local request = rpc.request
        rpc.request = function(method, params, callback)
          if method == 'initialize' and initialize_ms then
            vim.defer_fn(function() request(method, params, callback) end, initialize_ms)
            return true, 0
          end
          return request(method, params, callback)
        end
        return rpc
      end,
      filetypes = { 'text' },
      root_markers = { '.git' },
    })
    vim.lsp.enable('fake')
    vim.cmd.edit('a.txt')
  ]], tests_dir .. '/support/lsp_server.lua', initialize_ms)
  run('vim.wait(2000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end)')
  return run, job, editor
end

-- Returns the number of servers attached to the buffer of the file name.
local attached = [[return #vim.lsp.get_clients({ bufnr = vim.fn.bufnr(...) })]]

local run, job = start()
local diagnostics_before = run('vim.wait(1000, function() return #vim.diagnostic.get(0) > 0 end) return #vim.diagnostic.get(0)')
vim.wait(2000, function() return run(attached, 'a.txt') == 0 end)
equals(
  'a server with no use for longer than the limit stops, and its buffer stays open',
  { servers = run(attached, 'a.txt'), loaded = run('return vim.api.nvim_buf_is_loaded(vim.fn.bufnr(...))', 'a.txt') },
  { servers = 0, loaded = true }
)
equals(
  'the diagnostics of a stopped server go away',
  { before = diagnostics_before, after = run('return #vim.diagnostic.get(vim.fn.bufnr(...))', 'a.txt') },
  { before = 1, after = 0 }
)
vim.fn.jobstop(job)

local editor
run, job, editor = start()
-- Moves the cursor down and up every 100 ms for 1 second, which is more than three times the limit.
for _ = 1, 5 do
  vim.rpcrequest(editor, 'nvim_input', 'j')
  vim.wait(100)
  vim.rpcrequest(editor, 'nvim_input', 'k')
  vim.wait(100)
end
equals('cursor moves within the limit keep the server running', run(attached, 'a.txt'), 1)
vim.fn.jobstop(job)

-- Waits until the server stops, moves the cursor, and returns the number of servers of each file after a moment.
local function after_use(run, editor)
  vim.wait(2000, function() return run(attached, 'a.txt') == 0 end)
  vim.rpcrequest(editor, 'nvim_input', 'j')
  vim.wait(2000, function() return run(attached, 'a.txt') > 0 end)
  return { a = run(attached, 'a.txt'), b = run(attached, 'b.txt') }
end

run, job, editor = start()
equals('a cursor move in the buffer of a stopped server starts it again', after_use(run, editor).a, 1)
equals('the restart maps the LSP keys again', run([[return vim.fn.maparg('gd', 'n', false, true).buffer]]), 1)
vim.fn.jobstop(job)

run, job = start(600)
equals('a server that answers its start after the limit still attaches', run(attached, 'a.txt'), 1)
vim.fn.jobstop(job)

run, job, editor = start()
run([[
  vim.cmd.edit('b.txt')
  vim.wait(2000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end)
  vim.cmd.edit('a.txt')
]])
equals('the restart attaches the other open buffer of the root too', after_use(run, editor), { a = 1, b = 1 })
vim.fn.jobstop(job)

run, job, editor = start()
vim.wait(2000, function() return run(attached, 'a.txt') == 0 end)
run([[vim.v.errmsg = '']])
vim.rpcrequest(editor, 'nvim_input', 'K')
equals('K and gd of a stopped server leave the buffer, and K does nothing', run([[
  local k = vim.fn.maparg('K', 'n', false, true)
  return { k = { rhs = k.rhs, buffer = k.buffer }, gd = vim.fn.maparg('gd', 'n', false, true).buffer or 0, error = vim.v.errmsg }
]]), { k = { rhs = '<nop>', buffer = 0 }, gd = 0, error = '' })
vim.fn.jobstop(job)

report.finish()
