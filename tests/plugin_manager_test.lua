-- Run: tests/run.sh tests/plugin_manager_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check
local child_stdout = dofile(tests_dir .. '/support/child_stdout.lua')

local expected_plugins = {
  'nvim-treesitter/nvim-treesitter', 'brenoprata10/nvim-highlight-colors', 'keith/rspec.vim',
  'stevearc/conform.nvim',
  'christoomey/vim-tmux-navigator',
  'tpope/vim-projectionist', 'ibhagwan/fzf-lua', 'nvim-tree/nvim-web-devicons', 'folke/which-key.nvim',
  'nvim-mini/mini.surround',
  'tpope/vim-endwise',
  'nvim-tree/nvim-tree.lua', 'nvim-mini/mini.pairs',
  'lewis6991/gitsigns.nvim', 'nvim-lualine/lualine.nvim',
  'yssl/QFEnter', 'lifepillar/vim-solarized8', 'neovim/nvim-lspconfig',
  'mason-org/mason.nvim', 'saghen/blink.cmp', 'rafamadriz/friendly-snippets',
}

local function managed_plugins()
  local ok, lazy = pcall(require, 'lazy')
  if not ok then
    return nil
  end
  local repos = {}
  for _, plugin in ipairs(lazy.plugins()) do
    if plugin.name ~= 'lazy.nvim' then
      table.insert(repos, plugin[1])
    end
  end
  return repos
end

local managed = managed_plugins()
local expected = vim.deepcopy(expected_plugins)
table.sort(expected)
if managed then
  table.sort(managed)
end
check(
  'lazy.nvim manages exactly the expected plugins',
  vim.deep_equal(managed, expected),
  'expected ' .. #expected .. ' plugins, got ' .. vim.inspect(managed)
)

local function in_child(command, expression)
  return child_stdout({ '+silent! ' .. command, '+lua io.stdout:write(' .. expression .. ')', '+qa!' })
end

local default_rtp_of = child_stdout({ '--clean', '+lua io.stdout:write(vim.o.runtimepath)', '+qa' })

-- The plugins that load only for some files. One file of each one opens in a child.
local file_plugins = { 'nvim-highlight-colors', 'rspec.vim' }
local existing_css = vim.fn.tempname() .. '/style.css'
vim.fn.mkdir(vim.fs.dirname(existing_css), 'p')
vim.fn.writefile({ 'x' }, existing_css)
local opened_files = {
  {
    name = 'nvim-highlight-colors',
    check = 'opening an existing style.css loads nvim-highlight-colors',
    runtimepath_of = in_child('edit ' .. vim.fn.fnameescape(existing_css), 'vim.o.runtimepath'),
  },
  {
    name = 'rspec.vim',
    check = 'opening a new order_spec.rb loads rspec.vim',
    runtimepath_of = in_child('edit ' .. vim.fn.fnameescape(vim.fn.tempname() .. '/order_spec.rb'), 'vim.o.runtimepath'),
  },
}

local events_project = vim.fn.tempname()
for name, lines in pairs({ Gemfile = {}, ['package.json'] = { '{}' } }) do
  vim.fn.mkdir(events_project, 'p')
  vim.fn.writefile(lines, events_project .. '/' .. name)
end
local count_events = table.concat({
  '_G.counts = { FileType = 0, ProjectionistDetect = 0 }',
  "vim.api.nvim_create_autocmd('FileType', { callback = function() counts.FileType = counts.FileType + 1 end })",
  "vim.api.nvim_create_autocmd('User', { pattern = 'ProjectionistDetect', callback = function()",
  '  counts.ProjectionistDetect = counts.ProjectionistDetect + 1',
  'end })',
}, '\n')
local first_buffers = {}
for name, expected in vim.spairs({
  -- rspec.vim sets the filetype ruby first, then rspec.ruby.
  ['spec/order_spec.rb'] = '2 FileType, 2 ProjectionistDetect',
  ['app/style.css'] = '1 FileType, 1 ProjectionistDetect',
}) do
  local path = events_project .. '/' .. name
  vim.fn.mkdir(vim.fs.dirname(path), 'p')
  vim.fn.writefile({ 'x' }, path)
  table.insert(first_buffers, {
    check = 'opening ' .. name .. ' as the first buffer fires ' .. expected,
    expected = expected,
    counts_of = child_stdout({
      '+lua ' .. count_events,
      '+silent edit ' .. vim.fn.fnameescape(path),
      '+lua io.stdout:write(counts.FileType .. " FileType, " .. counts.ProjectionistDetect .. " ProjectionistDetect")',
      '+qa!',
    }),
  })
end

local default_rtp = default_rtp_of()
local rtp = vim.opt.runtimepath:get()
local dropped = vim.tbl_filter(function(dir)
  return vim.fn.isdirectory(dir) == 1 and not vim.tbl_contains(rtp, dir)
end, vim.split(default_rtp, ',', { trimempty = true }))
check(
  'the existing runtime dirs of a clean Neovim stay on runtimepath',
  #dropped == 0,
  'dropped ' .. vim.inspect(dropped)
)

local function plugin_dir(name)
  for _, plugin in ipairs(require('lazy').plugins()) do
    if plugin.name == name then
      return plugin.dir
    end
  end
end

check('fzf-lua is not loaded at startup', package.loaded['fzf-lua'] == nil, 'fzf-lua is loaded at startup')
check('nvim-tree is not loaded at startup', package.loaded['nvim-tree'] == nil, 'nvim-tree is loaded at startup')
check('mini.pairs is not loaded at startup', _G.MiniPairs == nil, 'MiniPairs exists at startup')
check('conform is not loaded at startup', package.loaded.conform == nil, 'conform is loaded at startup')
for _, name in ipairs({ 'nvim-treesitter', 'mini.surround', 'QFEnter' }) do
  local plugin = require('lazy.core.config').plugins[name]
  check(name .. ' is not loaded at startup', plugin ~= nil and plugin._.loaded == nil, name .. ' is loaded at startup')
end

local function loaded_file_plugins(dirs)
  local loaded = {}
  for _, name in ipairs(file_plugins) do
    if vim.tbl_contains(dirs, plugin_dir(name)) then
      table.insert(loaded, name)
    end
  end
  table.sort(loaded)
  return loaded
end

local at_startup = loaded_file_plugins(rtp)
check('no plugin that loads for a file is loaded at startup', #at_startup == 0, 'loaded ' .. vim.inspect(at_startup))

for _, opened in ipairs(opened_files) do
  local loaded = loaded_file_plugins(vim.split(opened.runtimepath_of(), ','))
  check(opened.check, vim.deep_equal(loaded, { opened.name }), 'loaded ' .. vim.inspect(loaded))
end

for _, first in ipairs(first_buffers) do
  local got = first.counts_of()
  check(first.check, got == first.expected, 'got ' .. got)
end

local project = vim.fn.tempname()
vim.fn.mkdir(project, 'p')

local function open(name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(project .. '/' .. name))
end

open('order_spec.rb')
check('a ruby spec file gets the rspec.ruby filetype', vim.bo.filetype == 'rspec.ruby', 'got ' .. vim.bo.filetype)

open('notes.md')
check('after/ftplugin of the config runs for markdown', vim.wo.spell, 'spell is off in a markdown buffer')

vim.fn.mkdir(project .. '/.git', 'p')
open('.git/COMMIT_EDITMSG')
local commit = vim.bo.filetype .. '/' .. tostring(vim.b.current_syntax)
check('.git/COMMIT_EDITMSG gets the gitcommit filetype and syntax', commit == 'gitcommit/gitcommit', 'got ' .. commit)

report.finish()
