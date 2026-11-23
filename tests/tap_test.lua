-- Run: tests/run.sh tests/tap_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local runner = dofile(tests_dir .. '/support/runner.lua')
local equals = report.equals

-- Runs the lines as a test file in a headless Neovim without the config, and returns its exit code and its stdout.
local function run_report(lines)
  local file = runner.report_file(lines)
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
  { code = 1, stdout = 'ok 1 - first\nnot ok 2 - second\n  ---\n  message: |\n    one\n    two\n  ...\n1..2\n' }
)

local without_run_line = {}
for _, file in ipairs(vim.fn.glob(tests_dir .. '/*_test.lua', false, true)) do
  local name = vim.fs.basename(file)
  if vim.fn.readfile(file, '', 1)[1] ~= '-- Run: tests/run.sh tests/' .. name then
    table.insert(without_run_line, name)
  end
end
equals('each test file starts with a Run comment that runs it with tests/run.sh', without_run_line, {})

local hanging = runner.hanging_file()
local timed_out = vim.system({ tests_dir .. '/tap-nvim.sh', hanging }, { env = { TEST_TIMEOUT = '1' }, stdin = false, text = true }):wait(20000)
local lines = vim.split(vim.trim(timed_out.stdout or ''), '\n')
equals(
  'a file that runs longer than TEST_TIMEOUT ends with a not ok line, and fails',
  { failed = timed_out.code ~= 0, last = lines[#lines] },
  { failed = true, last = 'not ok - ' .. hanging .. ' timed out after 1 s' }
)

report.finish()
