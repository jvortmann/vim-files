-- Writes test files and runs them through tests/tap-nvim.sh and tests/run.sh, for the tests of the runner.
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local M = {}

-- Writes the lines of Lua to a temporary test file, and returns its path. The lines see the report module as `report`.
function M.report_file(lines)
  local file = vim.fn.tempname() .. '_test.lua'
  vim.fn.writefile(vim.list_extend({ ('local report = dofile(%q)'):format(tests_dir .. '/support/report.lua') }, lines), file)
  return file
end

-- Writes a test file that never ends, and returns its path.
function M.hanging_file()
  local file = vim.fn.tempname() .. '.lua'
  vim.fn.writefile({ 'vim.wait(1e9)' }, file)
  return file
end

-- Runs tests/run.sh with the files and the extra environment variables env.
-- It returns a table with code, stdout and stderr.
function M.run_suite(files, env)
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
function M.parse_tap(tap)
  local result = vim.system({ 'perl', '-e', parse_script }, { stdin = tap, text = true }):wait(10000)
  return vim.json.decode(result.stdout)
end

return M
