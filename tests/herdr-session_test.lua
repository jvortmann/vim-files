-- Run: tests/run.sh tests/herdr-session_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local stub = dofile(tests_dir .. '/support/stub.lua')
local mason = dofile(tests_dir .. '/support/mason.lua')
local rpc = dofile(tests_dir .. '/support/rpc.lua')
local tasks = dofile(tests_dir .. '/support/tasks.lua')
local equals = report.equals

local terminal = 'test-terminal'
-- A child saves after this many milliseconds with no event, which keeps the test fast. A check that no save happens
-- waits no_save_ms, which is long enough for a save.
local quiet_ms = 50
local no_save_ms = 4 * quiet_ms

-- Returns a new home for a child. It has a work folder, a state folder, and a stub of hc that writes each call to a file.
-- home.env is the environment of a Herdr terminal with a fake tmux. It also says that the shell started nvim.
-- home.args gives the child the stub.
-- So a child cannot reach the real tmux, the real hc or the real state folder.
local function new_home()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir .. '/work', 'p')
  vim.fn.mkdir(dir .. '/state', 'p')
  stub.link(dir .. '/hc')
  return {
    dir = dir,
    work = dir .. '/work',
    session = dir .. '/state/nvim/sessions/' .. terminal .. '.vim',
    calls = dir .. '/calls',
    env = {
      HC_TERMINAL_ID = terminal,
      HERDR_RESTORE_NVIM = '1',
      XDG_STATE_HOME = dir .. '/state',
      TMUX = dir .. '/tmux,1,0',
      TMUX_PANE = '%0',
    },
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

-- Returns the calls to the stub that set the label restore.nvim. The server label module labels the terminal too.
local function restore_calls(home)
  return vim.tbl_filter(function(call) return call:find(' restore.nvim=', 1, true) ~= nil end, stub.calls(home.calls))
end

-- Each case below runs at the same time as the others, in a home of its own. It returns what it saw, and the checks
-- come after all of them, in the order of the cases.

local function label_case()
  local home = new_home()
  local run, job = start(home)
  run([[vim.cmd('split')]])
  local written = tasks.wait(5000, function() return exists(home.session) end)
  -- The stub creates its file a moment before it writes the call, so the test waits for the call itself.
  tasks.wait(2000, function() return #restore_calls(home) > 0 end)
  vim.fn.jobstop(job)
  return { written = written, calls = restore_calls(home), session = home.session }
end

-- Splits the window in the child, and returns whether it saves the session within 400 milliseconds. That is more than
-- quiet_ms and less than the default of 500, so the result shows which quiet time the child uses. The child measures
-- the time itself, so a late check of the test cannot change the result.
local function saved_soon(run)
  run([[
    local split_at = vim.uv.hrtime()
    vim.api.nvim_create_autocmd('SessionWritePost', {
      once = true,
      callback = function() vim.g.save_delay_ms = (vim.uv.hrtime() - split_at) / 1e6 end,
    })
    vim.cmd('split')
  ]])
  tasks.wait(2000, function() return run('return vim.g.save_delay_ms ~= nil') end)
  local delay = run('return vim.g.save_delay_ms or false')
  return delay ~= false and delay <= 400
end

local function quiet_case()
  local run, job = start(new_home())
  local saved = saved_soon(run)
  vim.fn.jobstop(job)
  return saved
end

local function default_quiet_case()
  local run, job = start(new_home(), {}, { '--cmd', 'unlet g:herdr_session_quiet_ms' })
  local saved = saved_soon(run)
  vim.fn.jobstop(job)
  return saved
end

-- Splits the window and waits longer than a save takes. Returns whether the file exists, and the calls to the stub.
local function after_split(home, env)
  local run, job = start(home, env)
  run([[vim.cmd('split')]])
  tasks.wait(no_save_ms)
  vim.fn.jobstop(job)
  return { file = exists(home.session), calls = stub.calls(home.calls) }
end

-- Calls action, and waits until the child writes the session again.
local function until_saved(run, action)
  local writes = run('return vim.g.session_writes')
  action()
  tasks.wait(5000, function() return run('return vim.g.session_writes') > writes end)
end

-- Starts nvim -S with a copy of the session file of the child that run reaches. The child can save again while a new
-- nvim reads the file, so the child reads the file itself, between two of its saves, and the copy is complete.
local function start_restore(run, home)
  local copy = home.dir .. '/restore.vim'
  vim.fn.writefile(run([[return vim.fn.readfile(..., 'b')]], home.session), copy, 'b')
  return start(home, { HC_TERMINAL_ID = false }, { '-S', copy })
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

local function layout_case()
  local home = new_home()
  for _, name in ipairs({ 'a.txt', 'b.txt' }) do
    vim.fn.writefile({ '1', '2', '3', '4', '5' }, home.work .. '/' .. name)
  end
  local run, job, editor = start(home, {}, { 'a.txt' })
  until_saved(run, function() run([[vim.cmd('3 | vsplit b.txt')]]) end)
  until_saved(run, function() vim.rpcrequest(editor, 'nvim_input', '4G') end)
  local restore_run, restore_job = start_restore(run, home)
  local splits = { restored = restore_run(layout), saved = run(layout) }
  vim.fn.jobstop(restore_job)
  until_saved(run, function() run([[vim.cmd('only')]]) end)
  restore_run, restore_job = start_restore(run, home)
  local closed = { restored = restore_run(layout), saved = run(layout) }
  vim.fn.jobstop(restore_job)
  local writes = run('return vim.g.session_writes')
  run([[vim.api.nvim_exec_autocmds('VimResized', {})]])
  local resized = tasks.wait(5000, function() return run('return vim.g.session_writes') > writes end)
  vim.fn.jobstop(job)
  return { splits = splits, closed = closed, resized = resized }
end

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
  local editor
  assert(tasks.wait(5000, function()
    editor = rpc.connect(socket)
    return editor ~= nil
  end), 'the nvim in the terminal opened no socket')
  assert(tasks.wait(5000, function() return exists(home.calls) end), 'the nvim in the terminal did not label it')
  return editor, job
end

-- Waits until nvim closes the channel editor. Nvim does that after it runs VimLeavePre.
local function until_exited(editor)
  assert(tasks.wait(5000, function() return next(vim.api.nvim_get_chan_info(editor)) == nil end), 'nvim did not exit')
end

-- Saves a split in nvim on a pseudo terminal, then quits it with command. Returns whether the session file existed
-- before and after the quit.
local function quit_case(command)
  local home = new_home()
  local editor, job = start_in_terminal(home)
  vim.rpcrequest(editor, 'nvim_command', 'split')
  local before = tasks.wait(5000, function() return exists(home.session) end)
  vim.rpcnotify(editor, 'nvim_command', command)
  until_exited(editor)
  vim.fn.jobstop(job)
  return { before = before, after = exists(home.session) }
end

-- Opens a file in nvim on a pseudo terminal, then calls stop with the job to end it. Returns whether the session file
-- holds that file after nvim exits.
local function saved_after(stop)
  local home = new_home()
  vim.fn.writefile({ 'x' }, home.work .. '/opened.txt')
  local editor, job = start_in_terminal(home)
  vim.rpcrequest(editor, 'nvim_command', 'edit opened.txt')
  stop(job)
  until_exited(editor)
  vim.fn.jobstop(job)
  return exists(home.session) and vim.fn.join(vim.fn.readfile(home.session), '\n'):find('opened.txt', 1, true) ~= nil
end

-- Closing the pseudo terminal hangs up nvim, as when Herdr stops.
local function hangup_case()
  return saved_after(vim.fn.jobstop)
end

-- SIGTERM to the terminal interface of nvim, as at a reboot. The server has its own process group and gets no signal,
-- so it only sees its interface go away.
local function client_term_case()
  return saved_after(function(job) vim.uv.kill(vim.fn.jobpid(job), 'sigterm') end)
end

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

local function side_windows_case()
  local home = new_home()
  vim.fn.writefile({ 'x' }, home.work .. '/a.txt')
  local run, job = start(home, {}, { 'a.txt' })
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
  local windows = run('return #vim.api.nvim_list_wins()')
  local restore_run, restore_job = start_restore(run, home)
  local restored = {
    windows = restore_run(layout),
    buffers = restore_run(listed),
    globals = restore_run([[return { map = vim.fn.maparg('<F12>', 'n'), report = vim.o.report }]]),
  }
  vim.fn.jobstop(restore_job)
  vim.fn.jobstop(job)
  return { windows = windows, restored = restored }
end

local function burst_case()
  local run, job = start(new_home())
  tasks.wait(no_save_ms)
  local writes = run('return vim.g.session_writes')
  run([[
    for _ = 1, 20 do
      vim.cmd('split')
      vim.cmd('close')
    end
  ]])
  tasks.wait(5000, function() return run('return vim.g.session_writes') > writes end)
  tasks.wait(no_save_ms)
  writes = run('return vim.g.session_writes') - writes
  vim.fn.jobstop(job)
  return writes
end

local function command_window_case()
  local run, job, editor = start(new_home())
  vim.rpcrequest(editor, 'nvim_input', 'q:')
  tasks.wait(5000, function() return run('return vim.fn.getcmdwintype()') == ':' end)
  run([[vim.v.errmsg = '' vim.api.nvim_exec_autocmds('VimResized', {})]])
  tasks.wait(no_save_ms, function() return run('return vim.v.errmsg') ~= '' end)
  local error = run('return vim.v.errmsg')
  vim.fn.jobstop(job)
  return error
end

-- Nvim runs `-c` commands before VimEnter, so a quit there ends nvim first. A session module that starts on VimEnter
-- then passed the check. The split and the quit run after VimEnter. The exit code 1 of cquit shows that they ran.
local headless_script = ([[
  lua vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = function()
    vim.cmd('split')
    vim.defer_fn(function() vim.cmd('cquit') end, %d)
  end })
]]):format(no_save_ms)

-- An nvim that the shell did not start, such as the editor of a commit message, has no HERDR_RESTORE_NVIM.
local function not_from_shell_case()
  local home = new_home()
  local result = after_split(home, { HERDR_RESTORE_NVIM = false })
  return { file = result.file, calls = restore_calls(home) }
end

-- Returns the value of HERDR_RESTORE_NVIM in a shell that nvim starts, or unset. env changes the environment of nvim.
local function child_variable_case(env)
  local run, job = start(new_home(), env)
  local value = run([[return vim.fn.system({ 'sh', '-c', 'printf %s "${HERDR_RESTORE_NVIM-unset}"' })]])
  vim.fn.jobstop(job)
  return value
end

local function headless_case()
  local home = new_home()
  local exit
  vim.system(
    vim.list_extend({ 'env', '-u', 'NVIM', vim.v.progpath, '-i', 'NONE', '--headless', '-c', headless_script }, home.args),
    { cwd = home.work, env = home.env, timeout = 10000 },
    function(result) exit = result.code end
  )
  tasks.wait(10000, function() return exit ~= nil end)
  return { file = exists(home.session), calls = stub.calls(home.calls), exit = exit }
end

local cases = {
  label_case,
  quiet_case,
  default_quiet_case,
  function() return after_split(new_home(), { NVIM = '/tmp/parent-nvim' }) end,
  function() return after_split(new_home(), { HC_TERMINAL_ID = false }) end,
  layout_case,
  function() return quit_case('qall') end,
  function() return quit_case('cquit') end,
  hangup_case,
  client_term_case,
  side_windows_case,
  burst_case,
  command_window_case,
  headless_case,
  not_from_shell_case,
  child_variable_case,
  function() return child_variable_case({ HC_TERMINAL_ID = false }) end,
}
local label, quiet, default_quiet, nested, outside, layout_result, quit, cquit, hangup, client_term, side, burst, command_window, headless, not_from_shell, child_variable, child_variable_outside =
  unpack(tasks.all(cases), 1, #cases)

equals('in Herdr, a split writes the session file', label.written, true)
equals('at start, nvim labels its terminal with the session file', label.calls, {
  'label ' .. terminal .. ' restore.nvim=' .. label.session,
})
equals('with g:herdr_session_quiet_ms at 50, a split saves the session within 400 ms', quiet, true)
equals('by default, a split waits 500 ms before it saves the session', default_quiet, false)
equals('an nvim inside nvim writes no file and calls no hc', nested, { file = false, calls = {} })
equals('outside Herdr, nvim writes no file and calls no hc', outside, { file = false, calls = {} })
equals('nvim -S brings back the splits and the cursors', layout_result.splits.restored, layout_result.splits.saved)
equals('closing a split saves the session', layout_result.closed.restored, layout_result.closed.saved)
equals('a resize of the terminal saves the session', layout_result.resized, true)
equals('a clean quit removes the session file', quit, { before = true, after = false })
equals('a quit with an error code, :cquit, removes the session file', cquit, { before = true, after = false })
equals('a hang-up of the terminal saves the session file', hangup, true)
equals('a SIGTERM to the terminal interface of nvim saves the session file', client_term, true)
equals('saving the session keeps every window open', side.windows, 6)
equals(
  'nvim -S brings back no side window, help, terminal or empty window',
  { windows = side.restored.windows, buffers = side.restored.buffers },
  { windows = { { 'a.txt', 1 } }, buffers = { 'a.txt' } }
)
equals('nvim -S brings back no global option or map', side.restored.globals, { map = '', report = 2 })
report.check('a burst of 20 splits and closes writes the session once or twice', burst >= 1 and burst <= 2, burst .. ' writes')
equals('a save while the command-line window is open shows no error', command_window, '')
equals(
  'a headless nvim, such as a script, writes no file and calls no hc',
  headless,
  { file = false, calls = {}, exit = 1 }
)
equals(
  'in Herdr, an nvim that the shell did not start writes no file and does not label the terminal',
  not_from_shell,
  { file = false, calls = {} }
)
equals('a program that nvim starts does not get HERDR_RESTORE_NVIM', child_variable, 'unset')
equals('outside Herdr, a program that nvim starts does not get HERDR_RESTORE_NVIM', child_variable_outside, 'unset')

report.finish()
