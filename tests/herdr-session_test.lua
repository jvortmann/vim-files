-- Run: nvim -i NONE --headless -c 'luafile tests/herdr-session_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local stub = dofile(tests_dir .. '/support/stub.lua')
local mason = dofile(tests_dir .. '/support/mason.lua')
local equals = report.equals

local terminal = 'test-terminal'
-- A child saves after this many milliseconds with no event, which keeps the test fast. A check that no save happens
-- waits no_save_ms, which is long enough for a save.
local quiet_ms = 50
local no_save_ms = 4 * quiet_ms

-- Returns a new home for a child. It has a work folder, a state folder, and a stub of hc that writes each call to a file.
-- home.env is the environment of a Herdr terminal with a fake tmux, and home.args gives the child the stub.
-- So a child cannot reach the real tmux, the real hc or the real state folder.
local function new_home()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir .. '/work', 'p')
  vim.fn.mkdir(dir .. '/state', 'p')
  stub.write(dir .. '/hc', dir .. '/calls')
  return {
    dir = dir,
    work = dir .. '/work',
    session = dir .. '/state/nvim/sessions/' .. terminal .. '.vim',
    calls = dir .. '/calls',
    env = { HC_TERMINAL_ID = terminal, XDG_STATE_HOME = dir .. '/state', TMUX = dir .. '/tmux,1,0', TMUX_PANE = '%0' },
    args = { '--cmd', ('let g:herdr_hc = %s | let g:herdr_session_quiet_ms = %d'):format(vim.fn.string(dir .. '/hc'), quiet_ms) },
  }
end

-- Starts a child in the work folder of home, as in a Herdr terminal. env changes its environment, and args adds arguments.
local function start(home, env, args)
  local editor, job = child.start({
    cwd = home.work,
    env = vim.tbl_extend('force', home.env, { NVIM = false }, env or {}),
    args = vim.list_extend(vim.deepcopy(home.args), args or {}),
  })
  local function run(code, ...)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
  end
  run([[
    vim.g.session_writes = 0
    vim.api.nvim_create_autocmd('SessionWritePost', {
      callback = function() vim.g.session_writes = vim.g.session_writes + 1 end,
    })
  ]])
  return run, job, editor
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local home = new_home()
local run, job = start(home)
run([[vim.cmd('split')]])
equals('in Herdr, a split writes the session file', vim.wait(5000, function() return exists(home.session) end), true)
vim.wait(5000, function() return exists(home.calls) end)
equals('at start, nvim labels its terminal with the session file', stub.calls(home.calls), {
  'label ' .. terminal .. ' restore.nvim=' .. home.session,
})
vim.fn.jobstop(job)

-- Splits the window in the child, and returns whether it saves the session within 400 milliseconds. That is more than
-- quiet_ms and less than the default of 500, so the result shows which quiet time the child uses.
local function saved_soon(run)
  local writes = run('return vim.g.session_writes')
  run([[vim.cmd('split')]])
  return vim.wait(400, function() return run('return vim.g.session_writes') > writes end)
end

run, job = start(new_home())
equals('with g:herdr_session_quiet_ms at 50, a split saves the session within 400 ms', saved_soon(run), true)
vim.fn.jobstop(job)
run, job = start(new_home(), {}, { '--cmd', 'unlet g:herdr_session_quiet_ms' })
equals('by default, a split waits 500 ms before it saves the session', saved_soon(run), false)
vim.fn.jobstop(job)

-- Splits the window and waits longer than a save takes. Returns whether the file exists, and the calls to the stub.
local function after_split(home, env)
  local run, job = start(home, env)
  run([[vim.cmd('split')]])
  vim.wait(no_save_ms)
  vim.fn.jobstop(job)
  return { file = exists(home.session), calls = stub.calls(home.calls) }
end

equals(
  'an nvim inside nvim writes no file and calls no hc',
  after_split(new_home(), { NVIM = '/tmp/parent-nvim' }),
  { file = false, calls = {} }
)
equals(
  'outside Herdr, nvim writes no file and calls no hc',
  after_split(new_home(), { HC_TERMINAL_ID = false }),
  { file = false, calls = {} }
)

-- Calls action, and waits until the child writes the session again.
local function until_saved(run, action)
  local writes = run('return vim.g.session_writes')
  action()
  vim.wait(5000, function() return run('return vim.g.session_writes') > writes end)
end

-- Returns the file name and the cursor line of each window in the tab of the child.
local layout = [[
  local found = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), ':t')
    table.insert(found, { name, vim.api.nvim_win_get_cursor(win)[1] })
  end
  return found
]]

home = new_home()
for _, name in ipairs({ 'a.txt', 'b.txt' }) do
  vim.fn.writefile({ '1', '2', '3', '4', '5' }, home.work .. '/' .. name)
end
local editor
run, job, editor = start(home, {}, { 'a.txt' })
until_saved(run, function() run([[vim.cmd('3 | vsplit b.txt')]]) end)
until_saved(run, function() vim.rpcrequest(editor, 'nvim_input', '4G') end)
local restore_run, restore_job = start(home, { HC_TERMINAL_ID = false }, { '-S', home.session })
equals('nvim -S brings back the splits and the cursors', restore_run(layout), run(layout))
vim.fn.jobstop(restore_job)
until_saved(run, function() run([[vim.cmd('only')]]) end)
restore_run, restore_job = start(home, { HC_TERMINAL_ID = false }, { '-S', home.session })
equals('closing a split saves the session', restore_run(layout), run(layout))
vim.fn.jobstop(restore_job)
local writes = run('return vim.g.session_writes')
run([[vim.api.nvim_exec_autocmds('VimResized', {})]])
equals(
  'a resize of the terminal saves the session',
  vim.wait(5000, function() return run('return vim.g.session_writes') > writes end),
  true
)
vim.fn.jobstop(job)

home = new_home()
run, job, editor = start(home)
until_saved(run, function() run([[vim.cmd('split')]]) end)
vim.rpcnotify(editor, 'nvim_command', 'qall')
vim.fn.jobwait({ job }, 5000)
equals('a clean quit removes the session file', exists(home.session), false)

-- Starts nvim with its terminal interface on a pseudo terminal, as in a Herdr pane. It waits until nvim labels the terminal.
local function start_in_terminal(home)
  local socket = vim.fn.tempname()
  local command = vim.list_extend({ 'env', '-u', 'NVIM', vim.v.progpath, '-i', 'NONE', '--listen', socket }, mason.args())
  local job = vim.fn.jobstart(vim.list_extend(command, home.args), {
    pty = true,
    width = 80,
    height = 24,
    cwd = home.work,
    env = home.env,
  })
  assert(vim.wait(5000, function() return exists(socket) end), 'the nvim in the terminal opened no socket')
  assert(vim.wait(5000, function() return exists(home.calls) end), 'the nvim in the terminal did not label it')
  return vim.fn.sockconnect('pipe', socket, { rpc = true }), job
end

home = new_home()
vim.fn.writefile({ 'x' }, home.work .. '/hangup.txt')
editor, job = start_in_terminal(home)
vim.rpcrequest(editor, 'nvim_command', 'edit hangup.txt')
-- Closing the pseudo terminal hangs up nvim, as when Herdr stops.
vim.fn.jobstop(job)
-- jobwait() returns at once for a stopped job on a pseudo terminal, so wait for the file.
equals(
  'a hang-up of the terminal saves the session file',
  vim.wait(5000, function()
    return exists(home.session) and vim.fn.join(vim.fn.readfile(home.session), '\n'):find('hangup.txt', 1, true) ~= nil
  end),
  true
)

-- Returns the file name of each listed buffer of the child.
local listed = [[
  local found = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      table.insert(found, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'))
    end
  end
  return found
]]

home = new_home()
vim.fn.writefile({ 'x' }, home.work .. '/a.txt')
run, job = start(home, {}, { 'a.txt' })
until_saved(run, function()
  run([[
    vim.cmd('NvimTreeOpen')
    vim.cmd('help')
    vim.cmd('botright new')
    vim.cmd('botright split | terminal')
    vim.cmd('copen')
    vim.keymap.set('n', '<F12>', ':echo 1<CR>')
    vim.o.report = 7
  ]])
end)
equals('saving the session keeps every window open', run('return #vim.api.nvim_list_wins()'), 6)
restore_run, restore_job = start(home, { HC_TERMINAL_ID = false }, { '-S', home.session })
equals(
  'nvim -S brings back no side window, help, terminal or empty window',
  { windows = restore_run(layout), buffers = restore_run(listed) },
  { windows = { { 'a.txt', 1 } }, buffers = { 'a.txt' } }
)
equals(
  'nvim -S brings back no global option or map',
  restore_run([[return { map = vim.fn.maparg('<F12>', 'n'), report = vim.o.report }]]),
  { map = '', report = 2 }
)
vim.fn.jobstop(restore_job)
vim.fn.jobstop(job)

run, job = start(new_home())
vim.wait(no_save_ms)
writes = run('return vim.g.session_writes')
run([[
  for _ = 1, 20 do
    vim.cmd('split')
    vim.cmd('close')
  end
]])
vim.wait(5000, function() return run('return vim.g.session_writes') > writes end)
vim.wait(no_save_ms)
writes = run('return vim.g.session_writes') - writes
report.check('a burst of 20 splits and closes writes the session once or twice', writes >= 1 and writes <= 2, writes .. ' writes')
vim.fn.jobstop(job)

run, job, editor = start(new_home())
vim.rpcrequest(editor, 'nvim_input', 'q:')
vim.wait(5000, function() return run('return vim.fn.getcmdwintype()') == ':' end)
run([[vim.v.errmsg = '' vim.api.nvim_exec_autocmds('VimResized', {})]])
vim.wait(no_save_ms, function() return run('return vim.v.errmsg') ~= '' end)
equals('a save while the command-line window is open shows no error', run('return vim.v.errmsg'), '')
vim.fn.jobstop(job)

home = new_home()
vim.system(
  vim.list_extend({ 'env', '-u', 'NVIM', vim.v.progpath, '-i', 'NONE', '--headless', '-c', 'split', '-c', 'sleep ' .. no_save_ms .. 'm', '-c', 'cquit' }, home.args),
  { cwd = home.work, env = home.env }
):wait(10000)
equals(
  'a headless nvim, such as a script, writes no file and calls no hc',
  { file = exists(home.session), calls = stub.calls(home.calls) },
  { file = false, calls = {} }
)

report.finish()
