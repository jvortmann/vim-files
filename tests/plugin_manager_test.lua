-- Run: nvim --headless -c 'luafile tests/plugin_manager_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local expected_plugins = {
  'nvim-treesitter/nvim-treesitter', 'aliou/bats.vim', 'tpope/vim-fireplace', 'ap/vim-css-color',
  'slashmili/alchemist.vim', 'avdgaag/vim-phoenix', 'andyl/vim-textobj-elixir', 'janko/vim-test',
  'keith/rspec.vim', 'slim-template/vim-slim', 'tpope/vim-rake', 'ngmy/vim-rubocop',
  'nelstrom/vim-textobj-rubyblock', 'prettier/vim-prettier', 'dense-analysis/ale', 'itchyny/vim-qfedit',
  'junegunn/vim-peekaboo', 'mattn/gist-vim', 'mattn/webapi-vim', 'mileszs/ack.vim',
  'radenling/vim-dispatch-neovim', 'romainl/vim-devdocs', 'tmux-plugins/vim-tmux',
  'christoomey/vim-tmux-navigator', 'tpope/vim-dispatch', 'tpope/vim-fugitive', 'tpope/vim-git',
  'tpope/vim-projectionist', 'junegunn/fzf', 'junegunn/fzf.vim', 'sunaku/vim-shortcut',
  'tpope/vim-unimpaired', 'tpope/vim-repeat', 'tpope/vim-ragtag', 'tpope/vim-surround',
  'tpope/vim-endwise', 'kopischke/vim-fetch', 'kana/vim-textobj-user', 'wellle/targets.vim',
  'scrooloose/nerdcommenter', 'scrooloose/nerdtree', 'Townk/vim-autoclose', 'majutsushi/tagbar',
  'Shougo/neosnippet', 'Shougo/neosnippet-snippets', 'airblade/vim-gitgutter', 'vim-airline/vim-airline',
  'vim-airline/vim-airline-themes', 'godlygeek/tabular', 'yssl/QFEnter', 'chriskempson/base16-vim',
  'baskerville/bubblegum', 'tomasr/molokai', 'lifepillar/vim-solarized8', 'dracula/vim', 'catppuccin/nvim',
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
  'lazy.nvim manages exactly the plugins of the old vim-plug list',
  vim.deep_equal(managed, expected),
  'expected ' .. #expected .. ' plugins, got ' .. vim.inspect(managed)
)

check(
  'nerdcommenter keeps its default mappings off, as its settings say',
  vim.fn.maparg('<leader>cc', 'n') == '',
  'got ' .. vim.inspect(vim.fn.maparg('<leader>cc', 'n'))
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

local filetype_plugins = {
  ['bats.vim'] = { 'bats' },
  ['vim-fireplace'] = { 'clojure' },
  ['vim-css-color'] = { 'css', 'sass', 'scss', 'less' },
  ['alchemist.vim'] = { 'elixir' },
  ['vim-phoenix'] = { 'elixir' },
  ['vim-textobj-elixir'] = { 'elixir' },
  ['rspec.vim'] = { 'ruby' },
  ['vim-rake'] = { 'ruby' },
  ['vim-rubocop'] = { 'ruby' },
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

local colorscheme_plugins = {
  ['base16-vim'] = 'base16-default-dark',
  bubblegum = 'bubblegum-256-dark',
  molokai = 'molokai',
  dracula = 'dracula',
  catppuccin = 'catppuccin-mocha',
}
for name, colorscheme in vim.spairs(colorscheme_plugins) do
  check(name .. ' is not loaded at startup', not vim.tbl_contains(rtp, plugin_dir(name)), plugin_dir(name) .. ' is on runtimepath')
  local got = in_child('colorscheme ' .. colorscheme, 'vim.g.colors_name')
  check('colorscheme ' .. colorscheme .. ' loads ' .. name, got == colorscheme, 'got ' .. got)
end

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

report.finish()
