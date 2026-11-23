-- Run: tests/run.sh tests/tap_failures_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local runner = dofile(tests_dir .. '/support/runner.lua')
local equals = report.equals
local run_suite = runner.run_suite

local failing = runner.report_file({ "report.check('second', false, 'the message\\nof the check')", 'report.finish()' })
local hanging = runner.hanging_file()
local crashing = runner.report_file({ "report.check('first', true)", "error('crash')" })
local suite = run_suite({ failing, hanging, crashing }, { TEST_TIMEOUT = '1' })
equals('a failing check, a timeout and a crash make their file not ok, the run fails, and a message shows once', {
  code = suite.code,
  run = runner.parse_tap(suite.stdout).run,
  message = select(2, suite.stdout:gsub('the message', '')),
  timeout = suite.stdout:find('    not ok - ' .. hanging .. ' timed out after 1 s\n', 1, true) ~= nil,
}, {
  code = 1,
  run = { plan = '1..4', passed = 1, failed = 3, errors = {} },
  message = 1,
  timeout = true,
})
equals('a crash shows its Lua error as comments, up to the last line of stderr, which has no newline', {
  error = suite.stdout:find('\n    # E5113: Lua chunk: ', 1, true) ~= nil,
  last = suite.stdout:find('in main chunk\nnot ok 3 - ' .. crashing, 1, true) ~= nil,
}, { error = true, last = true })
local two_failing = runner.report_file({ "report.check('a', true)", "report.check('b', false, 'b')", "report.check('c', false, 'c')", 'report.finish()' })
equals(
  'the summary counts the files and the checks apart, and the ShaDa check is a check',
  run_suite({ two_failing }).stdout:match('\n(# files: [^\n]*\n# checks: [^\n]*)\n# wall time %d+ms\n$'),
  '# files: 0 pass, 1 fail\n# checks: 2 pass, 2 fail'
)
equals('run.sh prints no tab, not even from the stack trace of a Lua error', suite.stdout:find('\t', 1, true), nil)

local no_plan, bad_plan, not_ok = vim.fn.tempname() .. '_test.lua', vim.fn.tempname() .. '_test.lua', vim.fn.tempname() .. '_test.lua'
vim.fn.writefile({ [[io.stdout:write('ok 1 - only\n')]], [[vim.cmd('qall!')]] }, no_plan)
vim.fn.writefile({ [[io.stdout:write('ok 1 - only\n1..2\n')]], [[vim.cmd('qall!')]] }, bad_plan)
vim.fn.writefile({ [[io.stdout:write('not ok 1 - raw\n1..1\n')]], [[vim.cmd('qall!')]] }, not_ok)
suite = run_suite({ no_plan, bad_plan, not_ok })
local tap = runner.parse_tap(suite.stdout)
equals('a file that exits with status 0 fails when it prints no plan, a wrong plan or a not ok line', {
  code = suite.code,
  run = tap.run,
  no_plan = tap.subtests[no_plan],
  bad_plan = tap.subtests[bad_plan],
  checks = suite.stdout:match('\n(# checks: [^\n]*)\n'),
  reasons = {
    suite.stdout:find('\n    not ok 2 - the file printed no plan\n', 1, true) ~= nil,
    suite.stdout:find('\n    not ok 2 - the plan is 1..2, but the file printed 1 test point\n', 1, true) ~= nil,
  },
}, {
  code = 1,
  run = { plan = '1..4', passed = 1, failed = 3, errors = {} },
  no_plan = { plan = '1..2', passed = 1, failed = 1, errors = {} },
  bad_plan = { plan = '1..2', passed = 1, failed = 1, errors = {} },
  checks = '# checks: 3 pass, 3 fail',
  reasons = { true, true },
})

report.finish()
