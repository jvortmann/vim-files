-- Run: tests/tap-nvim.sh tests/clipboard_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local child = dofile(tests_dir .. '/support/editor.lua')
local screen = dofile(tests_dir .. '/support/screen.lua')
local equals = report.equals

-- The config sets clipboard to unnamed, so a delete runs pbcopy. The harness puts a fake pbcopy and pbpaste first on
-- PATH, and TEST_CLIPBOARD names the file where the fake keeps the copied text.
local record = vim.env.TEST_CLIPBOARD
local fake = record and { pbcopy = vim.fs.dirname(record) .. '/pbcopy', pbpaste = vim.fs.dirname(record) .. '/pbpaste' }
local exepaths = [[return { pbcopy = vim.fn.exepath('pbcopy'), pbpaste = vim.fn.exepath('pbpaste') }]]
local is_fake = fake ~= nil and vim.deep_equal(loadstring(exepaths)(), fake)
equals('the nvim of a test file finds pbcopy and pbpaste in the fake folder of the harness', loadstring(exepaths)(), fake)

local function wait_for_copy()
  vim.wait(3000, function() return vim.uv.fs_stat(record) ~= nil and #vim.fn.readfile(record) > 0 end)
end

local delete = [[vim.api.nvim_buf_set_lines(0, 0, -1, false, { ... }) vim.cmd('normal! dd')]]

-- Runs code with text through run, which runs Lua in an nvim. Returns the pbcopy and pbpaste of that nvim and the
-- copied text. With no fake, it runs nothing, so a test never writes the clipboard of the user.
local function copied_by(run, code, text)
  if not is_fake then
    return 'no fake pbcopy, so nothing ran'
  end
  vim.fn.delete(record)
  run(code, text)
  wait_for_copy()
  local copied = vim.uv.fs_stat(record) and vim.fn.readfile(record) or {}
  return vim.tbl_extend('error', run(exepaths), { copied = copied })
end

local function expected(text)
  return vim.tbl_extend('error', fake or {}, { copied = { text } })
end

-- The nvim of a test file runs its test before VimEnter, and until then a delete does not sync the clipboard. A write to
-- the * register does.
equals(
  'a write to the * register in the nvim of a test file goes to the fake pbcopy',
  copied_by(function(code, ...) return loadstring(code)(...) end, [[vim.fn.setreg('*', ...)]], 'own line'),
  expected('own line')
)

local editor, job = child.start()
equals(
  'a delete in a child editor goes to the fake pbcopy',
  copied_by(function(code, ...) return vim.rpcrequest(editor, 'nvim_exec_lua', code, { ... }) end, delete, 'child line'),
  expected('child line')
)
vim.fn.jobstop(job)

-- Reads the clipboard while it is empty, then deletes a line and puts it back, in a new child editor. Returns what the
-- read gave and the lines after the put. With no fake, it runs nothing.
local function read_and_put()
  if not is_fake then
    return 'no fake pbcopy, so nothing ran'
  end
  vim.fn.delete(record)
  editor, job = child.start()
  local function run(code) return vim.rpcrequest(editor, 'nvim_exec_lua', code, {}) end
  local empty = run([[vim.cmd('messages clear') return { vim.fn.getreg('*'), vim.trim(vim.fn.execute('messages')) }]])
  run([[vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'put line' }) vim.cmd('normal! dd')]])
  wait_for_copy()
  run([[vim.cmd('normal! p')]])
  local lines = run('return vim.api.nvim_buf_get_lines(0, 0, -1, false)')
  vim.fn.jobstop(job)
  return { empty = empty, lines = lines }
end
equals(
  'the fake pbpaste reads an empty clipboard with no error, and a put gives back the deleted line',
  read_and_put(),
  { empty = { '', '' }, lines = { '', 'put line' } }
)

local pane = screen.start({})
equals('a delete in a tmux screen goes to the fake pbcopy', copied_by(pane.run, delete, 'screen line'), expected('screen line'))
pane.stop()

report.finish()
