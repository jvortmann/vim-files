-- Run: nvim -i NONE --headless -c 'luafile tests/tmux-navigator_test.lua' </dev/null
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
  stub.write(dir .. '/herdr-app', dir .. '/calls')
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

-- Types keys in the child, and waits a moment for one more call to the stub. Returns the calls that it got.
local function press(editor, file, keys)
  local before = #stub.calls(file)
  vim.rpcrequest(editor, 'nvim_input', keys)
  vim.wait(1000, function() return #stub.calls(file) > before end)
  return stub.calls(file)
end

local run, editor, job, file = start()
for _, keys in ipairs({ '<C-h>', '<C-j>', '<C-k>', '<C-l>' }) do
  press(editor, file, keys)
end
equals('in Herdr, ctrl-h/j/k/l at the edge moves the Herdr focus in that direction', stub.calls(file), {
  'do pane.go {"direction":"left"}',
  'do pane.go {"direction":"down"}',
  'do pane.go {"direction":"up"}',
  'do pane.go {"direction":"right"}',
})
vim.fn.jobstop(job)

run, editor, job, file = start()
local right = run([[vim.cmd('vsplit') return vim.api.nvim_get_current_win()]])
equals('in Herdr, ctrl-h inside nvim moves to the next window and leaves Herdr alone', {
  calls = press(editor, file, '<C-h>'),
  moved = run('return vim.api.nvim_get_current_win()') ~= right,
}, { calls = {}, moved = true })
vim.fn.jobstop(job)

run, editor, job = start({ HC_TERMINAL_ID = false })
equals(
  'outside Herdr, the commands are the ones of the plugin',
  run([[
    local found = {}
    for name, command in pairs(vim.api.nvim_get_commands({})) do
      if name:match('^TmuxNavigate') then
        found[name] = command.definition
      end
    end
    return found
  ]]),
  {
    TmuxNavigateLeft = "call s:TmuxAwareNavigate('h')",
    TmuxNavigateDown = "call s:TmuxAwareNavigate('j')",
    TmuxNavigateUp = "call s:TmuxAwareNavigate('k')",
    TmuxNavigateRight = "call s:TmuxAwareNavigate('l')",
    TmuxNavigatePrevious = "call s:TmuxAwareNavigate('p')",
  }
)
vim.fn.jobstop(job)

report.finish()
