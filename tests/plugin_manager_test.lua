-- Run: tests/run.sh tests/plugin_manager_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local expected_plugins = {
  'nvim-treesitter/nvim-treesitter', 'brenoprata10/nvim-highlight-colors', 'keith/rspec.vim',
  'stevearc/conform.nvim',
  'christoomey/vim-tmux-navigator', 'tpope/vim-fugitive',
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

report.equals(
  '<C-k> has no map in insert, select or visual mode after startup',
  { vim.fn.maparg('<C-k>', 'i'), vim.fn.maparg('<C-k>', 's'), vim.fn.maparg('<C-k>', 'x') },
  { '', '', '' }
)

report.equals(
  ']q and [q keep the built-in quickfix maps of Neovim',
  { vim.fn.maparg(']q', 'n', false, true).desc, vim.fn.maparg('[q', 'n', false, true).desc },
  { ':cnext', ':cprevious' }
)

-- Starts a child Neovim with this config and args. Returns a function that waits up to 10 seconds for the child and
-- returns its stdout. All children start before the first wait, so they run at the same time.
local function child_stdout(args)
  local child = vim.system(vim.list_extend({ vim.v.progpath, '-i', 'NONE', '--headless' }, args), { stdin = false, text = true })
  return function()
    local result = child:wait(10000)
    return result and result.stdout or ''
  end
end

local function in_child(command, expression)
  return child_stdout({ '+silent! ' .. command, '+lua io.stdout:write(' .. expression .. ')', '+qa!' })
end

local default_rtp_of = child_stdout({ '--clean', '+lua io.stdout:write(vim.o.runtimepath)', '+qa' })
local tree_after_toggle_of = in_child('NvimTreeToggle', 'tostring(package.loaded["nvim-tree"] ~= nil)')
local pairs_after_insert_of = in_child('doautocmd InsertEnter', 'tostring(_G.MiniPairs ~= nil)')
local conform_after_write_of = in_child('doautocmd BufWritePre', 'tostring(package.loaded.conform ~= nil)')
local catppuccin_file_of = in_child(
  'colorscheme catppuccin',
  '(function() for _, s in ipairs(vim.fn.getscriptinfo()) do if s.name:find("/colors/catppuccin", 1, true) then return s.name end end return "none" end)()'
)

local file_plugins = {
  ['nvim-highlight-colors'] = { 'style.css', 'style.sass', 'style.scss', 'style.less' },
  ['rspec.vim'] = { 'order_spec.rb', 'order_shared_examples.rb', 'order_shared_context.rb' },
}
local existing_files = vim.fn.tempname()
vim.fn.mkdir(existing_files, 'p')
local opened_files = {}
for name, files in vim.spairs(file_plugins) do
  for _, file in ipairs(files) do
    vim.fn.writefile({ 'x' }, existing_files .. '/' .. file)
    for kind, path in vim.spairs({
      ['an existing'] = existing_files .. '/' .. file,
      ['a new'] = vim.fn.tempname() .. '/' .. file,
    }) do
      table.insert(opened_files, {
        name = name,
        check = 'opening ' .. kind .. ' ' .. file .. ' loads ' .. name,
        runtimepath_of = in_child('edit ' .. vim.fn.fnameescape(path), 'vim.o.runtimepath'),
      })
    end
  end
end

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
  ['app/order.rb'] = '1 FileType, 1 ProjectionistDetect',
  -- rspec.vim sets the filetype ruby first, then rspec.ruby.
  ['spec/order_spec.rb'] = '2 FileType, 2 ProjectionistDetect',
  ['app/style.css'] = '1 FileType, 1 ProjectionistDetect',
  ['notes.md'] = '1 FileType, 1 ProjectionistDetect',
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
check('after/plugin of the config runs', vim.o.cpoptions:find('$', 1, true) ~= nil, 'cpoptions is ' .. vim.o.cpoptions)

local function plugin_dir(name)
  for _, plugin in ipairs(require('lazy').plugins()) do
    if plugin.name == name then
      return plugin.dir
    end
  end
end

check('fzf-lua is not loaded at startup', package.loaded['fzf-lua'] == nil, 'fzf-lua is loaded at startup')
for _, tool in ipairs({ 'fzf', 'rg' }) do
  check('fzf-lua finds ' .. tool .. ' on PATH', vim.fn.executable(tool) == 1, tool .. ' is not on PATH')
end

check('nvim-tree is not loaded at startup', package.loaded['nvim-tree'] == nil, 'nvim-tree is loaded at startup')
local tree_after_toggle = tree_after_toggle_of()
check('nvim-tree loads on NvimTreeToggle', tree_after_toggle == 'true', 'nvim-tree after NvimTreeToggle: ' .. tree_after_toggle)

check('mini.pairs is not loaded at startup', _G.MiniPairs == nil, 'MiniPairs exists at startup')
local pairs_after_insert = pairs_after_insert_of()
check('mini.pairs loads on InsertEnter', pairs_after_insert == 'true', 'MiniPairs after InsertEnter: ' .. pairs_after_insert)

check('conform is not loaded at startup', package.loaded.conform == nil, 'conform is loaded at startup')
local conform_after_write = conform_after_write_of()
check('conform loads on BufWritePre', conform_after_write == 'true', 'conform after BufWritePre: ' .. conform_after_write)

local function loaded_file_plugins(dirs)
  local loaded = {}
  for name in pairs(file_plugins) do
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

check('solarized8 is the active colorscheme', vim.g.colors_name == 'solarized8', 'got ' .. tostring(vim.g.colors_name))

local catppuccin_file = catppuccin_file_of()
local builtin_catppuccin = vim.fn.resolve(vim.env.VIMRUNTIME .. '/colors/catppuccin.vim')
check(
  'colorscheme catppuccin loads the built-in file of the runtime',
  vim.fn.resolve(catppuccin_file) == builtin_catppuccin,
  'expected ' .. builtin_catppuccin .. ', got ' .. catppuccin_file
)

local project = vim.fn.tempname()
vim.fn.mkdir(project, 'p')

local function open(name)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(project .. '/' .. name))
end

open('order_spec.rb')
check('a ruby spec file gets the rspec.ruby filetype', vim.bo.filetype == 'rspec.ruby', 'got ' .. vim.bo.filetype)
check(
  'treesitter highlights a ruby buffer',
  vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil,
  'no treesitter highlighter on ' .. vim.api.nvim_buf_get_name(0)
)

open('notes.md')
check('after/ftplugin of the config runs for markdown', vim.wo.spell, 'spell is off in a markdown buffer')

vim.fn.mkdir(project .. '/.git/rebase-merge', 'p')
for name, filetype in vim.spairs({
  ['.git/COMMIT_EDITMSG'] = 'gitcommit',
  ['.git/rebase-merge/git-rebase-todo'] = 'gitrebase',
  ['.gitconfig'] = 'gitconfig',
  ['.tmux.conf'] = 'tmux',
}) do
  open(name)
  local got = vim.bo.filetype .. '/' .. tostring(vim.b.current_syntax)
  check(name .. ' gets the ' .. filetype .. ' filetype and syntax', got == filetype .. '/' .. filetype, 'got ' .. got)
end

open('.git/COMMIT_EDITMSG')
local commit_settings = vim.bo.spelllang .. ' ' .. vim.wo.colorcolumn .. ' ' .. tostring(vim.wo.spell)
check(
  'after/ftplugin of the config runs for gitcommit',
  commit_settings == 'en_us,en_gb 51,73 true',
  'got ' .. commit_settings
)

for name, filetype in vim.spairs({
  ['app.ex'] = 'elixir',
  ['core.clj'] = 'clojure',
  ['page.slim'] = '',
  ['suite.bats'] = 'sh',
}) do
  vim.v.errmsg = ''
  open(name)
  local got = vim.inspect(vim.bo.filetype) .. ' ' .. vim.inspect(vim.v.errmsg)
  check(
    name .. ' opens with ' .. (filetype == '' and 'no filetype' or 'the runtime filetype ' .. filetype) .. ' and no error',
    got == vim.inspect(filetype) .. ' ""',
    'got ' .. got
  )
end

report.finish()
