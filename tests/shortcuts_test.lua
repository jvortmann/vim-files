-- Run: nvim -i NONE --headless -c 'luafile tests/shortcuts_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

-- The projectionist plugin defines :A, :AS and :AV only in a buffer of a project that it knows, such as one with a Gemfile.
local root = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(root .. '/lib', 'p')
vim.fn.writefile({}, root .. '/Gemfile')
vim.fn.system({ 'git', 'init', '-q', root })
vim.cmd('silent edit ' .. vim.fn.fnameescape(root .. '/lib/order.rb'))

-- Neovim records the file of a Lua map only when 'verbose' is on, and this editor did not start with it. So a
-- child editor with -V1 lists the maps from lua/config/keymaps and from the keys of the plugin specs, which
-- lazy.nvim sets.
local list_maps = table.concat({
  'local ours = {}',
  'for _, info in ipairs(vim.fn.getscriptinfo()) do',
  "  for _, part in ipairs({ '/lua/config/keymaps/', '/lazy/core/handler/keys.lua' }) do",
  '    if info.name:find(part, 1, true) then ours[info.sid] = true end',
  '  end',
  'end',
  'local maps = {}',
  "for _, mode in ipairs({ 'n', 'x', 'o', 'i' }) do",
  '  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do',
  '    if ours[map.sid] and map.rhs then table.insert(maps, map.rhs) end',
  '  end',
  'end',
  'io.stdout:write(vim.json.encode(maps))',
}, ' ')
local listed = vim.system(
  { vim.v.progpath, '-i', 'NONE', '-V1/dev/null', '--headless', '+lua ' .. list_maps, '+qa!' },
  { stdin = false }
):wait()
local rhs_list = vim.json.decode(listed.stdout)

local missing = {}
for _, rhs in ipairs(rhs_list) do
  for name in rhs:gmatch(':(%u%w*)') do
    if vim.fn.exists(':' .. name) ~= 2 then
      missing[':' .. name] = true
    end
  end
  for name in rhs:gmatch(':call%s+([%w_#.:<>]+)') do
    local script_local = name:match('^s:') or name:match('^<SNR>') or name:match('^v:')
    if not script_local and vim.fn.exists('*' .. name) ~= 1 then
      missing[name .. '()'] = true
    end
  end
end

local names = vim.tbl_keys(missing)
table.sort(names)
equals('every shortcut calls an existing command or function', names, {})

report.finish()
