-- Run: nvim --headless -c 'luafile tests/plugin_manager_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local expected_plugins = {
  'nvim-treesitter/nvim-treesitter', 'ap/vim-css-color', 'keith/rspec.vim',
  'nelstrom/vim-textobj-rubyblock', 'prettier/vim-prettier', 'dense-analysis/ale', 'itchyny/vim-qfedit',
  'junegunn/vim-peekaboo', 'mileszs/ack.vim',
  'christoomey/vim-tmux-navigator', 'tpope/vim-fugitive',
  'tpope/vim-projectionist', 'junegunn/fzf', 'junegunn/fzf.vim', 'sunaku/vim-shortcut',
  'tpope/vim-unimpaired', 'tpope/vim-repeat', 'tpope/vim-ragtag', 'nvim-mini/mini.surround',
  'tpope/vim-endwise', 'kopischke/vim-fetch', 'kana/vim-textobj-user', 'wellle/targets.vim',
  'scrooloose/nerdtree', 'nvim-mini/mini.pairs', 'majutsushi/tagbar',
  'Shougo/neosnippet', 'Shougo/neosnippet-snippets', 'airblade/vim-gitgutter', 'vim-airline/vim-airline',
  'vim-airline/vim-airline-themes', 'yssl/QFEnter', 'lifepillar/vim-solarized8',
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

check('ack.vim defines Ack with the rg command of its settings', vim.fn.exists(':Ack') == 2, 'Ack is missing')
check(
  'ragtag adds its global insert mappings, as its settings say',
  vim.fn.maparg('<C-X>/', 'i') ~= '',
  'the <C-X>/ insert mapping is missing'
)

local function child_stdout(args)
  return vim.system(vim.list_extend({ vim.v.progpath, '--headless' }, args), { stdin = false }):wait().stdout
end

local function in_child(command, expression)
  return child_stdout({ '+silent! ' .. command, '+lua io.stdout:write(' .. expression .. ')', '+qa!' })
end

local default_rtp = child_stdout({ '--clean', '+lua io.stdout:write(vim.o.runtimepath)', '+qa' })
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

for name, built in pairs({ ['vim-prettier'] = 'node_modules/.bin/prettier', fzf = 'bin/fzf' }) do
  local path = plugin_dir(name) .. '/' .. built
  check('the build of ' .. name .. ' made ' .. built, vim.fn.executable(path) == 1, path .. ' is missing')
end

local command_plugins = {
  { plugin = 'nerdtree', defines = 'NERDTree', triggers = { 'NERDTreeToggle' } },
  { plugin = 'tagbar', defines = 'TagbarToggle', triggers = { 'Tagbar', 'TagbarOpenAutoClose' } },
}

for _, case in ipairs(command_plugins) do
  check(
    case.plugin .. ' is not loaded at startup',
    vim.fn.exists(':' .. case.defines) ~= 2,
    ':' .. case.defines .. ' exists at startup'
  )
  for _, trigger in ipairs(case.triggers) do
    local got = in_child(trigger, 'vim.fn.exists(":' .. case.defines .. '")')
    check(case.plugin .. ' loads on ' .. trigger, got == '2', ':' .. case.defines .. ' after ' .. trigger .. ', got ' .. got)
  end
end

check('mini.pairs is not loaded at startup', _G.MiniPairs == nil, 'MiniPairs exists at startup')
local pairs_after_insert = in_child('doautocmd InsertEnter', 'tostring(_G.MiniPairs ~= nil)')
check('mini.pairs loads on InsertEnter', pairs_after_insert == 'true', 'MiniPairs after InsertEnter: ' .. pairs_after_insert)

local filetype_plugins = {
  ['vim-css-color'] = { 'css', 'sass', 'scss', 'less' },
  ['rspec.vim'] = { 'ruby' },
  ['vim-textobj-rubyblock'] = { 'ruby' },
  ['vim-prettier'] = { 'javascript', 'typescript', 'css', 'less', 'scss', 'json', 'ruby', 'markdown', 'yaml', 'html' },
}

local function loaded_filetype_plugins(dirs)
  local loaded = {}
  for name in pairs(filetype_plugins) do
    if vim.tbl_contains(dirs, plugin_dir(name)) then
      table.insert(loaded, name)
    end
  end
  table.sort(loaded)
  return loaded
end

local at_startup = loaded_filetype_plugins(rtp)
check('no filetype plugin is loaded at startup', #at_startup == 0, 'loaded ' .. vim.inspect(at_startup))

local filetypes = {}
for name, types in pairs(filetype_plugins) do
  for _, filetype in ipairs(types) do
    filetypes[filetype] = filetypes[filetype] or {}
    table.insert(filetypes[filetype], name)
  end
end
for filetype, expected_names in vim.spairs(filetypes) do
  table.sort(expected_names)
  local loaded = loaded_filetype_plugins(vim.split(in_child('setfiletype ' .. filetype, 'vim.o.runtimepath'), ','))
  check(
    'the ' .. filetype .. ' filetype loads ' .. table.concat(expected_names, ', '),
    vim.deep_equal(loaded, expected_names),
    'loaded ' .. vim.inspect(loaded)
  )
end

check('solarized8 is the active colorscheme', vim.g.colors_name == 'solarized8', 'got ' .. tostring(vim.g.colors_name))

local catppuccin_file = in_child(
  'colorscheme catppuccin',
  '(function() for _, s in ipairs(vim.fn.getscriptinfo()) do if s.name:find("/colors/catppuccin", 1, true) then return s.name end end return "none" end)()'
)
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
