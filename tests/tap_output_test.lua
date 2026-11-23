-- Run: tests/run.sh tests/tap_output_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local runner = dofile(tests_dir .. '/support/runner.lua')
local equals = report.equals
local run_suite = runner.run_suite

local passing = runner.report_file({ "report.check('passes', true)", 'report.finish()' })
local passing_run = run_suite({ passing }, { COLOR = 'auto' })
equals('run.sh prints TAP version 14 that passes, with a subtest for each file and the ShaDa check last', {
  code = passing_run.code,
  tap = runner.parse_tap(passing_run.stdout),
}, {
  code = 0,
  tap = {
    first = 'TAP version 14',
    run = { plan = '1..2', passed = 2, failed = 0, errors = {} },
    subtests = { [passing] = { plan = '1..1', passed = 1, failed = 0, errors = {} } },
  },
})
equals(
  'run.sh prints the plan of the run after the version line, and the plan of a file after its Subtest line',
  vim.list_slice(vim.split(passing_run.stdout, '\n'), 1, 4),
  { 'TAP version 14', '1..2', '# Subtest: ' .. passing, '    1..1' }
)
local colored = run_suite({ passing }, { COLOR = 'always' }).stdout
equals('run.sh colors its output with COLOR=always, and prints no color to a pipe', {
  pipe = passing_run.stdout:find('\27[', 1, true) ~= nil,
  ok = colored:find('\27[32mok 1 - ' .. passing, 1, true) ~= nil,
  subtest = colored:find('\27[1m# Subtest: ' .. passing, 1, true) ~= nil,
}, { pipe = false, ok = true, subtest = true })

local suite = run_suite({ passing })
local output = suite.stdout .. suite.stderr
equals(
  'run.sh runs only the files that it gets',
  { code = suite.code, ran = output:find(passing, 1, true) ~= nil, others = output:find('tests/grep_test.lua', 1, true) ~= nil },
  { code = 0, ran = true, others = false }
)
equals(
  'run.sh finds a file name relative to the folder of the caller',
  vim.system({ tests_dir .. '/run.sh', vim.fs.basename(passing) }, { cwd = vim.fs.dirname(passing), stdin = false }):wait(15000).code,
  0
)

equals(
  'a file in the repo shows by its path from the root of the repo',
  run_suite({ tests_dir .. '/keymaps_test.lua' }).stdout:match('\nok 1 %- (%S+) # time='),
  'tests/keymaps_test.lua'
)

report.finish()
