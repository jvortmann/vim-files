-- Run: tests/run.sh tests/tmux-navigator_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local stub = dofile(tests_dir .. '/support/stub.lua')
local equals = report.equals

-- Starts a child as in a Herdr terminal, with a fake tmux, a temporary state folder and a herdr-app stub.
-- The stub writes each call to a file. So a child cannot reach the real tmux, the real Herdr or the real state folder.
-- The option env changes the environment of the child. Returns a function that runs Lua in the child, the channel, the job and the file of the calls.
local function start(env)
  local dir = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(dir .. '/state', 'p')
  stub.link(dir .. '/herdr-app')
  local editor, job = child.start({
    env = vim.tbl_extend('force', {
      HC_TERMINAL_ID = 'test-terminal',
      XDG_STATE_HOME = dir .. '/state',
      TMUX = dir .. '/tmux,1,0',
      TMUX_PANE = '%0',
    }, env or {}),
    args = { '--cmd', 'let g:herdr_app = ' .. vim.fn.string(dir .. '/herdr-app') },
  })
  local function run(code, ...)
    return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... })
  end
  return run, editor, job, dir .. '/calls'
end

-- Types keys in the child, and waits up to timeout milliseconds for one more call to the stub.
-- Returns the calls that came after the keys. The stub runs in the background, so a call can come late.
local function press(editor, file, keys, timeout)
  local before = #stub.calls(file)
  vim.rpcrequest(editor, 'nvim_input', keys)
  vim.wait(timeout, function() return #stub.calls(file) > before end)
  return vim.list_slice(stub.calls(file), before + 1)
end

local run, editor, job, file = start()
local moves = {}
for _, key in ipairs({ 'h', 'j', 'k', 'l' }) do
  moves[key] = press(editor, file, '<C-' .. key .. '>', 5000)
end
equals('in Herdr, ctrl-h/j/k/l at the edge moves the Herdr focus in that direction', moves, {
  h = { 'do pane.go {"direction":"left"}' },
  j = { 'do pane.go {"direction":"down"}' },
  k = { 'do pane.go {"direction":"up"}' },
  l = { 'do pane.go {"direction":"right"}' },
})
vim.fn.jobstop(job)

run, editor, job, file = start()
local right = run([[vim.cmd('vsplit') return vim.api.nvim_get_current_win()]])
-- A wrong call to Herdr can take more than 300 ms to reach the stub, so the check waits 1 second for it.
equals('in Herdr, ctrl-h inside nvim moves to the next window and leaves Herdr alone', {
  calls = press(editor, file, '<C-h>', 1000),
  moved = run('return vim.api.nvim_get_current_win()') ~= right,
}, { calls = {}, moved = true })
vim.fn.jobstop(job)

report.finish()
