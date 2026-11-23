-- Run: tests/run.sh tests/projectionist_alternates_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local root

local function touch(path)
  local full = root .. '/' .. path
  vim.fn.mkdir(vim.fn.fnamemodify(full, ':h'), 'p')
  vim.fn.writefile({}, full)
end

local function new_project(marker)
  root = vim.fn.resolve(vim.fn.tempname())
  vim.fn.mkdir(root, 'p')
  touch(marker)
  vim.fn.system({ 'git', 'init', '-q', root })
end

local function alternates(path)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(root .. '/' .. path))
  local relative = {}
  for _, file in ipairs(vim.fn['projectionist#query_file']('alternate')) do
    table.insert(relative, (file:gsub('^' .. vim.pesc(root) .. '/', '')))
  end
  return relative
end

local function first_existing(path)
  for _, file in ipairs(alternates(path)) do
    if vim.fn.filereadable(root .. '/' .. file) == 1 then
      return file
    end
  end
  return nil
end

local function jumps(from, to)
  touch(from)
  touch(to)
  local got = first_existing(from)
  check(
    from .. ' jumps to ' .. to,
    got == to,
    'got ' .. tostring(got) .. ' from candidates ' .. vim.inspect(alternates(from))
  )
end

local test_folders = { 'tests', 'test', 'spec', 'specs' }
local test_suffixes = { 'test', 'spec' }

local function offers_only_sources(from, ext)
  local tests = vim.tbl_filter(function(file)
    return file:match('%.test%.' .. ext .. '$') ~= nil or file:match('%.spec%.' .. ext .. '$') ~= nil
  end, alternates(from))
  check(from .. ' offers only source files', #tests == 0, 'got test candidates ' .. vim.inspect(tests))
end

local function prefers_mirrored_test(ext)
  local source = 'src/both.' .. ext
  local mirrored = 'tests/both.test.' .. ext
  touch(source)
  touch('src/both.test.' .. ext)
  touch(mirrored)
  local got = first_existing(source)
  check(
    source .. ' prefers the mirrored test over the colocated test',
    got == mirrored,
    'got ' .. tostring(got)
  )
end

local function check_extension(ext)
  local function file(name)
    return name .. '.' .. ext
  end

  jumps(file('src/coloc'), file('src/coloc.test'))
  jumps(file('src/coloc.test'), file('src/coloc'))
  jumps(file('src/colspec'), file('src/colspec.spec'))
  jumps(file('src/colspec.spec'), file('src/colspec'))
  jumps(file('src/auth/login'), file('tests/auth/login.test'))
  jumps(file('tests/auth/login.test'), file('src/auth/login'))

  for _, folder in ipairs(test_folders) do
    for _, suffix in ipairs(test_suffixes) do
      local tail = folder .. '_' .. suffix
      jumps(file('src/mirror/' .. tail), file(folder .. '/mirror/' .. tail .. '.' .. suffix))
      jumps(file(folder .. '/back/' .. tail .. '.' .. suffix), file('src/back/' .. tail))
      jumps(file('app/' .. tail), file(folder .. '/app/' .. tail .. '.' .. suffix))
      jumps(file(folder .. '/lib/' .. tail .. '.' .. suffix), file('lib/' .. tail))
      offers_only_sources(file(folder .. '/back/' .. tail .. '.' .. suffix), ext)
    end
  end

  offers_only_sources(file('src/coloc.test'), ext)
  offers_only_sources(file('src/colspec.spec'), ext)
  offers_only_sources(file('tests/auth/login.test'), ext)
  prefers_mirrored_test(ext)
end

new_project('mise.toml')
check_extension('ts')
-- The config builds the same projections for each extension in one loop, so two jumps show that the loop covers the
-- other extensions.
for _, ext in ipairs({ 'tsx', 'js', 'jsx' }) do
  jumps('src/auth/login.' .. ext, 'tests/auth/login.test.' .. ext)
  jumps('tests/auth/login.test.' .. ext, 'src/auth/login.' .. ext)
end

new_project('package.json')
touch('src/auth/login.ts')
touch('tests/auth/login.test.ts')
local got = first_existing('src/auth/login.ts')
check(
  'a project with only package.json jumps from src/auth/login.ts to tests/auth/login.test.ts',
  got == 'tests/auth/login.test.ts',
  'got ' .. tostring(got) .. ' from candidates ' .. vim.inspect(alternates('src/auth/login.ts'))
)

report.finish()
