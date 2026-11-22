-- Run: nvim -i NONE --headless -c 'luafile tests/tap_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

-- Writes the lines of Lua to a temporary test file, and returns its path. The lines see the report module as `report`.
local function report_file(lines)
  local file = vim.fn.tempname() .. '_test.lua'
  vim.fn.writefile(vim.list_extend({ ('local report = dofile(%q)'):format(tests_dir .. '/support/report.lua') }, lines), file)
  return file
end

-- Runs the lines as a test file in a headless Neovim without the config, and returns its exit code and its stdout.
local function run_report(lines)
  local file = report_file(lines)
  local result = vim.system(
    { vim.v.progpath, '--clean', '-i', 'NONE', '--headless', '-c', 'luafile ' .. file, '-c', 'cquit' },
    { stdin = false, text = true }
  ):wait(10000)
  return { code = result.code, stdout = result.stdout }
end

equals(
  'a passing check prints a numbered ok line and the plan on stdout',
  run_report({ "report.check('first', true)", 'report.finish()' }),
  { code = 0, stdout = 'ok 1 - first\n1..1\n' }
)
equals(
  'a failing check prints a not ok line with its message in a YAML block, and the file fails',
  run_report({ "report.check('first', true)", "report.check('second', false, 'one\\ntwo')", 'report.finish()' }),
  { code = 1, stdout = 'ok 1 - first\nnot ok 2 - second\n  ---\n  message: |-\n    one\n    two\n  ...\n1..2\n' }
)

local hanging = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'vim.wait(1e9)' }, hanging)
local timed_out = vim.system({ tests_dir .. '/tap-nvim.sh', hanging }, { env = { TEST_TIMEOUT = '1' }, stdin = false, text = true }):wait(20000)
local lines = vim.split(vim.trim(timed_out.stdout or ''), '\n')
equals(
  'a file that runs longer than TEST_TIMEOUT ends with a not ok line, and fails',
  { failed = timed_out.code ~= 0, last = lines[#lines] },
  { failed = true, last = 'not ok - ' .. hanging .. ' timed out after 1 s' }
)

-- Runs tests/run.sh with the files, and returns its exit code and its stdout and stderr as one string.
local function run_suite(files)
  local result = vim.system(vim.list_extend({ tests_dir .. '/run.sh' }, files), { stdin = false, text = true }):wait(15000)
  return result.code, (result.stdout or '') .. (result.stderr or '')
end

local passing = report_file({ "report.check('passes', true)", 'report.finish()' })
local code, output = run_suite({ passing })
equals(
  'run.sh runs only the files that it gets',
  { code = code, ran = output:find(passing, 1, true) ~= nil, others = output:find('tests/grep_test.lua', 1, true) ~= nil },
  { code = 0, ran = true, others = false }
)
equals(
  'run.sh finds a file name relative to the folder of the caller',
  vim.system({ tests_dir .. '/run.sh', vim.fs.basename(passing) }, { cwd = vim.fs.dirname(passing), stdin = false }):wait(15000).code,
  0
)

local failing = report_file({ "report.check('second', false, 'one\\ntwo')", 'report.finish()' })
code, output = run_suite({ failing })
equals(
  'run.sh fails on a failing check and shows its file, name and message',
  { failed = code ~= 0, message = output:find(failing .. ': second: one\ntwo', 1, true) ~= nil },
  { failed = true, message = true }
)

report.finish()
