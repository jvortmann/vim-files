-- Run: tests/run.sh tests/lsp_idle_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local tasks = dofile(tests_dir .. '/support/tasks.lua')
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

-- Each case below runs at the same time as the others, with a child of its own. It returns what it saw, and the checks
-- come after all of them, in the order of the cases.

local function stop_case()
  local run, job = start()
  local diagnostics_before = run('vim.wait(1000, function() return #vim.diagnostic.get(0) > 0 end) return #vim.diagnostic.get(0)')
  tasks.wait(2000, function() return run(attached, 'a.txt') == 0 end)
  local result = {
    servers = run(attached, 'a.txt'),
    loaded = run('return vim.api.nvim_buf_is_loaded(vim.fn.bufnr(...))', 'a.txt'),
    diagnostics_before = diagnostics_before,
    diagnostics_after = run('return #vim.diagnostic.get(vim.fn.bufnr(...))', 'a.txt'),
  }
  vim.fn.jobstop(job)
  return result
end

local function keep_alive_case()
  local run, job = start()
  -- Moves the cursor down and up every 100 ms for 1 second, which is more than three times the limit. A timer in
  -- the child types the keys and counts the servers after the last move, so a slow step of the test cannot change
  -- the result.
  run([[
    local timer, moves = vim.uv.new_timer(), 0
    timer:start(100, 100, vim.schedule_wrap(function()
      if moves == 10 then
        return
      end
      moves = moves + 1
      vim.api.nvim_input(moves % 2 == 1 and 'j' or 'k')
      if moves == 10 then
        timer:stop()
        vim.g.servers_after_moves = #vim.lsp.get_clients({ bufnr = vim.fn.bufnr('a.txt') })
      end
    end))
  ]])
  tasks.wait(5000, function() return run('return vim.g.servers_after_moves ~= nil') end)
  local servers = run('return vim.g.servers_after_moves')
  vim.fn.jobstop(job)
  return servers
end

-- Waits until the server stops, moves the cursor, and returns the number of servers of each file after a moment.
local function after_use(run, editor)
  tasks.wait(2000, function() return run(attached, 'a.txt') == 0 end)
  vim.rpcrequest(editor, 'nvim_input', 'j')
  tasks.wait(2000, function() return run(attached, 'a.txt') > 0 end)
  return { a = run(attached, 'a.txt'), b = run(attached, 'b.txt') }
end

local function restart_case()
  local run, job, editor = start()
  local result = { servers = after_use(run, editor).a, gd_buffer = run([[return vim.fn.maparg('gd', 'n', false, true).buffer]]) }
  vim.fn.jobstop(job)
  return result
end

local function slow_start_case()
  local run, job = start(600)
  local servers = run(attached, 'a.txt')
  vim.fn.jobstop(job)
  return servers
end

local function other_buffer_case()
  local run, job, editor = start()
  run([[
    vim.cmd.edit('b.txt')
    vim.wait(2000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end)
    vim.cmd.edit('a.txt')
  ]])
  local servers = after_use(run, editor)
  vim.fn.jobstop(job)
  return servers
end

local function stopped_keys_case()
  local run, job, editor = start()
  tasks.wait(2000, function() return run(attached, 'a.txt') == 0 end)
  run([[vim.v.errmsg = '']])
  vim.rpcrequest(editor, 'nvim_input', 'K')
  local keys = run([[
    local k = vim.fn.maparg('K', 'n', false, true)
    return { k = { rhs = k.rhs, buffer = k.buffer }, gd = vim.fn.maparg('gd', 'n', false, true).buffer or 0, error = vim.v.errmsg }
  ]])
  vim.fn.jobstop(job)
  return keys
end

-- The case of the slow server comes last. Its start blocks the test for 600 ms, so a case after it would start late.
local cases = { keep_alive_case, stop_case, restart_case, other_buffer_case, stopped_keys_case, slow_start_case }
local keep_alive, stop, restart, other_buffer, stopped_keys, slow_start = unpack(tasks.all(cases), 1, #cases)

equals(
  'a server with no use for longer than the limit stops, and its buffer stays open',
  { servers = stop.servers, loaded = stop.loaded },
  { servers = 0, loaded = true }
)
equals(
  'the diagnostics of a stopped server go away',
  { before = stop.diagnostics_before, after = stop.diagnostics_after },
  { before = 1, after = 0 }
)
equals('cursor moves within the limit keep the server running', keep_alive, 1)
equals('a cursor move in the buffer of a stopped server starts it again', restart.servers, 1)
equals('the restart maps the LSP keys again', restart.gd_buffer, 1)
equals('a server that answers its start after the limit still attaches', slow_start, 1)
equals('the restart attaches the other open buffer of the root too', other_buffer, { a = 1, b = 1 })
equals('K and gd of a stopped server leave the buffer, and K does nothing', stopped_keys, { k = { rhs = '<nop>', buffer = 0 }, gd = 0, error = '' })

report.finish()
