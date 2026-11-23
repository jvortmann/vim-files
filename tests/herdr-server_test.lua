-- Run: tests/run.sh tests/herdr-server_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local stub = dofile(tests_dir .. '/support/stub.lua')
local mason = dofile(tests_dir .. '/support/mason.lua')
local rpc = dofile(tests_dir .. '/support/rpc.lua')
local tasks = dofile(tests_dir .. '/support/tasks.lua')
local equals = report.equals

local terminal = 'test-terminal'
-- A check that no call happens waits this long, which is long enough for a call.
local no_call_ms = 200

-- Returns a new home for a child. It has a state folder and a stub of hc that writes each call to a file.
-- home.env is the environment of a Herdr terminal with a fake tmux, and home.args gives the child the stub.
-- So a child cannot reach the real tmux, the real hc or the real state folder.
local function new_home()
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir .. '/state', 'p')
  stub.link(dir .. '/hc')
  return {
    dir = dir,
    calls = dir .. '/calls',
    env = { HC_TERMINAL_ID = terminal, XDG_STATE_HOME = dir .. '/state', TMUX = dir .. '/tmux,1,0', TMUX_PANE = '%0' },
    args = { '--cmd', 'let g:herdr_hc = ' .. vim.fn.string(dir .. '/hc') },
  }
end

-- Starts a child in home, as in a Herdr terminal. env changes its environment.
local function start(home, env)
  return child.start({
    cwd = home.dir,
    env = vim.tbl_extend('force', home.env, { NVIM = false }, env or {}),
    args = home.args,
  })
end

-- Returns the calls to the stub that set the label nvim.server. The session module labels the terminal too.
local function server_calls(home)
  return vim.tbl_filter(function(call) return call:find(' nvim.server=', 1, true) ~= nil end, stub.calls(home.calls))
end

-- Each case below runs at the same time as the others, in a home of its own. It returns what it saw, and the checks
-- come after all of them, in the order of the cases.

local function label_case()
  local home = new_home()
  local editor, job = start(home)
  local server = vim.rpcrequest(editor, 'nvim_get_vvar', 'servername')
  tasks.wait(2000, function() return #server_calls(home) > 0 end)
  local calls = server_calls(home)
  vim.fn.jobstop(job)
  return { server = server, calls = calls }
end

local function quit_case()
  local home = new_home()
  local editor, job = start(home)
  local server = vim.rpcrequest(editor, 'nvim_get_vvar', 'servername')
  tasks.wait(2000, function() return #server_calls(home) > 0 end)
  vim.rpcnotify(editor, 'nvim_command', 'qall')
  tasks.wait(5000, function() return #server_calls(home) > 1 end)
  vim.fn.jobstop(job)
  return { server = server, calls = server_calls(home) }
end

-- Starts nvim with its terminal interface on a pseudo terminal, as in a Herdr pane. It stops its server in --cmd, so
-- v:servername is empty when the interface attaches. Returns the address of the label, and the v:servername that the
-- nvim at that address gives, or false when nothing answers there.
local function no_server_case()
  local home = new_home()
  local command = vim.list_extend({ 'env', '-u', 'NVIM', vim.v.progpath, '-i', 'NONE' }, mason.args())
  vim.list_extend(command, home.args)
  vim.list_extend(command, { '--cmd', 'call serverstop(v:servername)' })
  local job = vim.fn.jobstart(command, { pty = true, width = 80, height = 24, cwd = home.dir, env = home.env })
  tasks.wait(5000, function() return #server_calls(home) > 0 end)
  local labeled = (server_calls(home)[1] or ''):match('nvim%.server=(.*)$') or ''
  local editor
  tasks.wait(2000, function()
    editor = labeled ~= '' and rpc.connect(labeled) or nil
    return editor ~= nil
  end)
  local answered = editor and vim.rpcrequest(editor, 'nvim_get_vvar', 'servername') or false
  vim.fn.jobstop(job)
  return { labeled = labeled, answered = answered }
end

-- Starts a child with env, quits it, and returns every call to the stub, at start or at the quit.
local function start_and_quit(env)
  local home = new_home()
  local editor, job = start(home, env)
  tasks.wait(no_call_ms)
  vim.rpcnotify(editor, 'nvim_command', 'qall')
  tasks.wait(5000, function() return vim.fn.jobwait({ job }, 0)[1] ~= -1 end)
  tasks.wait(no_call_ms)
  return stub.calls(home.calls)
end

local function headless_case()
  local home = new_home()
  local done = false
  vim.system(
    vim.list_extend({ 'env', '-u', 'NVIM', vim.v.progpath, '-i', 'NONE', '--headless', '-c', 'sleep ' .. no_call_ms .. 'm', '-c', 'qall' }, home.args),
    { cwd = home.dir, env = home.env, timeout = 10000 },
    function() done = true end
  )
  tasks.wait(10000, function() return done end)
  tasks.wait(no_call_ms)
  return stub.calls(home.calls)
end

local cases = {
  label_case,
  headless_case,
  function() return start_and_quit({ NVIM = '/tmp/parent-nvim' }) end,
  function() return start_and_quit({ HC_TERMINAL_ID = false }) end,
  quit_case,
  no_server_case,
}
local label, headless, nested, outside, quit, no_server = unpack(tasks.all(cases), 1, #cases)

equals('at start, nvim labels its terminal with its server address', label.calls, {
  'label ' .. terminal .. ' nvim.server=' .. label.server,
})
equals('a headless nvim, such as a script, calls no hc', headless, {})
equals('an nvim inside nvim calls no hc', nested, {})
equals('outside Herdr, nvim calls no hc', outside, {})
equals('a quit removes the label', quit.calls, {
  'label ' .. terminal .. ' nvim.server=' .. quit.server,
  'label ' .. terminal .. ' nvim.server=',
})
equals('with no server, nvim starts one and labels its terminal with it', no_server.answered, no_server.labeled)

report.finish()
