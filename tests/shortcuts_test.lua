-- Run: nvim --headless -c 'luafile tests/shortcuts_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

-- The projectionist plugin defines :A, :AS and :AV only in a buffer of a project that it knows, such as one with a Gemfile.
local root = vim.fn.resolve(vim.fn.tempname())
vim.fn.mkdir(root .. '/lib', 'p')
vim.fn.writefile({}, root .. '/Gemfile')
vim.fn.system({ 'git', 'init', '-q', root })
vim.cmd('silent edit ' .. vim.fn.fnameescape(root .. '/lib/order.rb'))

-- A map that the Shortcut command defines has the script of vim-shortcut as its source.
local shortcut_scripts = {}
for _, info in ipairs(vim.fn.getscriptinfo()) do
  if info.name:find('/conf/shortcuts/', 1, true) or info.name:find('/vim-shortcut/plugin/', 1, true) then
    shortcut_scripts[info.sid] = true
  end
end

local missing = {}
for _, mode in ipairs({ 'n', 'x', 'o', 'i' }) do
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if shortcut_scripts[map.sid] and map.rhs then
      for name in map.rhs:gmatch(':(%u%w*)') do
        if vim.fn.exists(':' .. name) ~= 2 then
          missing[':' .. name] = true
        end
      end
      for name in map.rhs:gmatch(':call%s+([%w_#.:<>]+)') do
        local script_local = name:match('^s:') or name:match('^<SNR>') or name:match('^v:')
        if not script_local and vim.fn.exists('*' .. name) ~= 1 then
          missing[name .. '()'] = true
        end
      end
    end
  end
end

local names = vim.tbl_keys(missing)
table.sort(names)
equals('every shortcut calls an existing command or function', names, {})

report.finish()
