-- Run: nvim --headless -c 'luafile tests/fugitive_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')
local equals = report.equals

local git_at_startup = vim.fn.exists(':Git')

local undescribed = keymaps.undescribed({ '<F7>', '<S-F7>' })

-- Records each command line and cancels it, so that Git blame does not run.
local typed = {}
vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    table.insert(typed, vim.fn.getcmdline())
    vim.cmd('let v:event.abort = v:true')
  end,
})

-- Returns the command lines that F7 types when pressed in dir.
local function f7_command(dir)
  vim.cmd.cd(vim.fn.fnameescape(dir))
  typed = {}
  pcall(vim.api.nvim_feedkeys, vim.keycode('<F7>'), 'mx', false)
  vim.cmd('silent! only')
  return typed
end

local plain = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(plain, 'p')
local with_ignore_revs = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(with_ignore_revs, 'p')
vim.fn.writefile({}, with_ignore_revs .. '/.git-blame-ignore-revs')

-- After nvim_feedkeys, the next message starts without a newline. So type all keys first, and report the checks after.
local without_file = f7_command(plain)
local with_file = f7_command(with_ignore_revs)
io.stdout:write('\n')

equals('fugitive is loaded at startup, before any key', git_at_startup, 2)
equals('every fugitive map has a description for which-key', undescribed, {})
equals('F7 runs Git blame when the directory has no .git-blame-ignore-revs', without_file, { 'Git blame' })
equals(
  'F7 runs Git blame with the revisions of .git-blame-ignore-revs when the file exists',
  with_file,
  { 'Git blame --ignore-revs-file .git-blame-ignore-revs' }
)

report.finish()
