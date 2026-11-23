-- Run: tests/run.sh tests/tap_test.lua
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

local hanging = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'vim.wait(1e9)' }, hanging)
local timed_out = vim.system({ tests_dir .. '/tap-nvim.sh', hanging }, { env = { TEST_TIMEOUT = '1' }, stdin = false, text = true }):wait(20000)
local lines = vim.split(vim.trim(timed_out.stdout or ''), '\n')
equals(
  'a file that runs longer than TEST_TIMEOUT ends with a not ok line, and fails',
  { failed = timed_out.code ~= 0, last = lines[#lines] },
  { failed = true, last = 'not ok - ' .. hanging .. ' timed out after 1 s' }
)

-- Runs tests/run.sh with the files and the extra environment variables env.
-- It returns a table with code, stdout and stderr.
local function run_suite(files, env)
  local result = vim.system(vim.list_extend({ tests_dir .. '/run.sh' }, files), { env = env, stdin = false, text = true }):wait(15000)
  return { code = result.code, stdout = result.stdout or '', stderr = result.stderr or '' }
end

-- A Perl script that summarizes TAP with TAP::Parser: the whole stream, and each subtest on its own without its indent.
-- TAP::Parser 3.43 knows TAP up to version 13, so the summary drops the parse error about version 14.
local parse_script = [=[
  use TAP::Parser;
  use JSON::PP;
  local $/;
  my $tap = <STDIN>;
  sub summary {
    my $parser = TAP::Parser->new({ tap => shift });
    while ($parser->next) {}
    my @errors = grep { !/versions later than 13/ } $parser->parse_errors;
    return { plan => $parser->plan, passed => scalar($parser->passed), failed => scalar($parser->failed), errors => \@errors };
  }
  my (%subtests, $name, @lines);
  for (split /\n/, $tap) {
    if (/^# Subtest: (.*)/) { ($name, @lines) = ($1); next }
    if (defined $name && s/^    //) { push @lines, $_; next }
    if (defined $name) { $subtests{$name} = summary(join("\n", @lines) . "\n"); undef $name }
  }
  print encode_json({ first => (split /\n/, $tap)[0], run => summary($tap), subtests => \%subtests });
]=]
local function parse_tap(tap)
  local result = vim.system({ 'perl', '-e', parse_script }, { stdin = tap, text = true }):wait(10000)
  return vim.json.decode(result.stdout)
end

local passing = report_file({ "report.check('passes', true)", 'report.finish()' })
local passing_run = run_suite({ passing }, { COLOR = 'auto' })
equals('run.sh prints TAP version 14 that passes, with a subtest for each file and the ShaDa check last', {
  code = passing_run.code,
  tap = parse_tap(passing_run.stdout),
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

local failing = report_file({ "report.check('second', false, 'the message\\nof the check')", 'report.finish()' })
local crashing = report_file({ "report.check('first', true)", "error('crash')" })
suite = run_suite({ failing, hanging, crashing }, { TEST_TIMEOUT = '1' })
equals('a failing check, a timeout and a crash make their file not ok, the run fails, and a message shows once', {
  code = suite.code,
  run = parse_tap(suite.stdout).run,
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
local two_failing = report_file({ "report.check('a', true)", "report.check('b', false, 'b')", "report.check('c', false, 'c')", 'report.finish()' })
equals(
  'the summary counts the files and the checks apart, and the ShaDa check is a check',
  run_suite({ two_failing }).stdout:match('\n(# files: [^\n]*\n# checks: [^\n]*)\n# wall time %d+ms\n$'),
  '# files: 0 pass, 1 fail\n# checks: 2 pass, 2 fail'
)
equals('run.sh prints no tab, not even from the stack trace of a Lua error', suite.stdout:find('\t', 1, true), nil)

equals(
  'a file in the repo shows by its path from the root of the repo',
  run_suite({ tests_dir .. '/keymaps_test.lua' }).stdout:match('\nok 1 %- (%S+) # time='),
  'tests/keymaps_test.lua'
)

local slow = report_file({ 'vim.wait(1000)', "report.check('slow', true)", 'report.finish()' })
local quick = report_file({ "report.check('quick', true)", 'report.finish()' })
local ordered = run_suite({ slow, quick }, { JOBS = '2' }).stdout
equals('run.sh prints the files in their order, even when a later file finishes first', {
  order = ordered:find('# Subtest: ' .. slow, 1, true) < ordered:find('# Subtest: ' .. quick, 1, true),
  slow_first_finished_last = tonumber(ordered:match('ok 1 %- [^\n]+ # time=(%d+)ms')) > tonumber(ordered:match('ok 2 %- [^\n]+ # time=(%d+)ms')),
}, { order = true, slow_first_finished_last = true })

local no_plan, bad_plan, not_ok = vim.fn.tempname() .. '_test.lua', vim.fn.tempname() .. '_test.lua', vim.fn.tempname() .. '_test.lua'
vim.fn.writefile({ [[io.stdout:write('ok 1 - only\n')]], [[vim.cmd('qall!')]] }, no_plan)
vim.fn.writefile({ [[io.stdout:write('ok 1 - only\n1..2\n')]], [[vim.cmd('qall!')]] }, bad_plan)
vim.fn.writefile({ [[io.stdout:write('not ok 1 - raw\n1..1\n')]], [[vim.cmd('qall!')]] }, not_ok)
suite = run_suite({ no_plan, bad_plan, not_ok })
local tap = parse_tap(suite.stdout)
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
