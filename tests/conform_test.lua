-- Run: nvim -i NONE --headless -c 'luafile tests/conform_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals
local run_scheduled = dofile(tests_dir .. '/support/scheduled.lua')
local lsp_server = dofile(tests_dir .. '/support/lsp_server.lua')

local notified = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
  if (level or vim.log.levels.INFO) >= vim.log.levels.WARN then
    table.insert(notified, message)
  end
  return notify(message, level, opts)
end

local function errors_after(failure)
  -- conform sends its notices in a scheduled callback.
  run_scheduled()
  local errors = vim.list_extend(failure and { failure } or {}, notified)
  if vim.v.errmsg ~= '' then
    table.insert(errors, vim.v.errmsg)
  end
  return errors
end

local function project(files)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  for name, lines in pairs(files or {}) do
    vim.fn.mkdir(vim.fs.dirname(dir .. '/' .. name), 'p')
    vim.fn.writefile(lines, dir .. '/' .. name)
  end
  return dir
end

local function save(dir, name, lines)
  local path = dir .. '/' .. name
  vim.fn.writefile(lines, path)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
  vim.bo.modified = true
  vim.v.errmsg = ''
  notified = {}
  local ok, err = pcall(vim.cmd, 'silent write')
  return { content = vim.fn.readfile(path), errors = errors_after(not ok and err or nil) }
end

local function press(dir, name, lines, keys)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(dir .. '/' .. name))
  vim.api.nvim_buf_set_lines(0, 0, -1, true, lines)
  vim.v.errmsg = ''
  notified = {}
  vim.api.nvim_feedkeys(vim.keycode(keys), 'mx', false)
  vim.wait(3000, function()
    return not vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, true), lines)
  end)
  local errors = errors_after()
  local content = vim.api.nvim_buf_get_lines(0, 0, -1, true)
  vim.cmd('silent bwipeout!')
  return { content = content, errors = errors }
end

local function start_formatting_server(dir, new_text)
  vim.lsp.start({
    name = 'formatting-server',
    root_dir = dir,
    cmd = lsp_server.cmd({
      initialize = { capabilities = { documentFormattingProvider = true } },
      ['textDocument/formatting'] = {
        { range = { start = { line = 0, character = 0 }, ['end'] = { line = 1, character = 0 } }, newText = new_text },
      },
    }),
  })
end

local with_config = project({ ['.prettierrc'] = { '{}' } })
local without_config = project()

-- After nvim_feedkeys, the next message starts without a newline. So feed all keys first, and report the checks after.
local pressed = press(without_config, 'new.js', { 'const  a = {b:1}' }, '<leader>p')
local selected = press(without_config, 'range.js', { 'const  a = 1', 'const  b = 2', 'const  c = 3' }, 'jV<leader>p')
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.txt',
  once = true,
  callback = function() start_formatting_server(without_config, 'formatted by the server\n') end,
})
local from_server = press(without_config, 'notes.txt', { 'written' }, '<leader>p')

equals(
  'saving a .js file in a folder with a prettier config and no node_modules formats it with the global prettier',
  save(with_config, 'app.js', { 'const  a = {b:1}' }),
  { content = { 'const a = { b: 1 };' }, errors = {} }
)
equals(
  'saving a .md file in a folder with a prettier config formats it',
  save(with_config, 'notes.md', { '* one', '* two' }),
  { content = { '- one', '- two' }, errors = {} }
)

local css = { written = { 'a{color:red}' }, formatted = { 'a {', '  color: red;', '}' } }
local jsx = { written = { 'const a = <div  id="x"/>' }, formatted = { 'const a = <div id="x" />;' } }
for name, case in vim.spairs({
  ['app.jsx'] = jsx,
  ['app.ts'] = { written = { 'const  a : number=1' }, formatted = { 'const a: number = 1;' } },
  ['app.tsx'] = jsx,
  ['style.css'] = css,
  ['style.less'] = css,
  ['style.scss'] = css,
  ['data.json'] = { written = { '{"a":1}' }, formatted = { '{ "a": 1 }' } },
  ['schema.graphql'] = { written = { 'type Query{a:Int}' }, formatted = { 'type Query {', '  a: Int', '}' } },
  ['app.vue'] = {
    written = { '<template><div  id="x"></div></template>' },
    formatted = { '<template><div id="x"></div></template>' },
  },
  ['config.yml'] = { written = { 'a:   1' }, formatted = { 'a: 1' } },
  ['page.html'] = { written = { '<p  id="x">hi</p>' }, formatted = { '<p id="x">hi</p>' } },
}) do
  equals(
    'saving ' .. name .. ' in a folder with a prettier config formats it, as vim-prettier did',
    save(with_config, name, case.written),
    { content = case.formatted, errors = {} }
  )
end

equals(
  'saving a .js file in a folder without a prettier config leaves it as written',
  save(without_config, 'app.js', { 'const  a = {b:1}' }),
  { content = { 'const  a = {b:1}' }, errors = {} }
)
equals(
  'saving a .js file in a folder whose package.json has a prettier key formats it',
  save(project({ ['package.json'] = { '{ "prettier": {} }' } }), 'app.js', { 'const  a = {b:1}' }),
  { content = { 'const a = { b: 1 };' }, errors = {} }
)
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*/saved.txt',
  once = true,
  callback = function() start_formatting_server(without_config, 'formatted by the server\n') end,
})
equals(
  'saving a file with no formatter for its filetype formats it through the language server',
  save(without_config, 'saved.txt', { 'written' }),
  { content = { 'formatted by the server' }, errors = {} }
)
equals(
  '<leader>p formats a buffer in a folder without a prettier config',
  pressed,
  { content = { 'const a = { b: 1 };' }, errors = {} }
)
equals(
  '<leader>p in visual mode formats only the selected lines',
  selected,
  { content = { 'const  a = 1', 'const b = 2;', 'const  c = 3' }, errors = {} }
)
equals(
  '<leader>p formats through the language server when no formatter is set for the filetype',
  from_server,
  { content = { 'formatted by the server' }, errors = {} }
)

local ruby_plugin = project({
  ['.prettierrc'] = { '{ "plugins": ["@prettier/plugin-ruby"] }' },
  ['node_modules/@prettier/plugin-ruby/package.json'] = { '{ "name": "@prettier/plugin-ruby", "main": "index.js" }' },
  ['node_modules/@prettier/plugin-ruby/index.js'] = {
    'module.exports = {',
    "  languages: [{ name: 'Ruby', parsers: ['ruby'], extensions: ['.rb'] }],",
    '  parsers: {',
    "    ruby: { parse: (text) => ({ text }), astFormat: 'ruby', locStart: () => 0, locEnd: (node) => node.text.length },",
    '  },',
    "  printers: { ruby: { print: (path) => path.node.text.replace(/  +/g, ' ') } },",
    '};',
  },
})
for _, name in ipairs({ 'app.rb', 'order_spec.rb' }) do
  equals(
    'saving ' .. name .. ' in a project with the prettier ruby plugin formats it',
    save(ruby_plugin, name, { 'x  =  1' }),
    { content = { 'x = 1' }, errors = {} }
  )
end
equals(
  'saving a ruby file in a folder with a prettier config and no ruby plugin leaves it as written, with no error',
  save(with_config, 'app.rb', { 'x  =  1' }),
  { content = { 'x  =  1' }, errors = {} }
)

report.finish()
