-- Run: tests/run.sh tests/tap_order_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local runner = dofile(tests_dir .. '/support/runner.lua')
local equals = report.equals
local run_suite = runner.run_suite

-- run.sh writes the file 1.done in its work folder when the second file ends. The slow file waits for it, so the quick
-- file always finishes first.
local slow = runner.report_file({
  "report.check('slow', vim.wait(10000, function() return vim.uv.fs_stat(vim.env.work .. '/1.done') ~= nil end, 10))",
  'report.finish()',
})
local quick = runner.report_file({ "report.check('quick', true)", 'report.finish()' })
local ordered = run_suite({ slow, quick }, { JOBS = '2' })
local stdout = ordered.stdout
equals('run.sh prints the files in their order, even when a later file finishes first', {
  code = ordered.code,
  order = stdout:find('# Subtest: ' .. slow, 1, true) < stdout:find('# Subtest: ' .. quick, 1, true),
  slow_first_finished_last = tonumber(stdout:match('ok 1 %- [^\n]+ # time=(%d+)ms')) > tonumber(stdout:match('ok 2 %- [^\n]+ # time=(%d+)ms')),
}, { code = 0, order = true, slow_first_finished_last = true })

report.finish()
