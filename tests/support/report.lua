local failures = {}
local count = 0
-- The test file that loads this module with dofile, relative to the current folder.
local test_file = vim.fn.fnamemodify(debug.getinfo(3, 'S').source:sub(2), ':.')

local report = {}

function report.check(name, ok, detail)
  count = count + 1
  if ok then
    io.stdout:write(('ok %d - %s\n'):format(count, name))
  else
    local message = detail:gsub('\n', '\n    ')
    io.stdout:write(('not ok %d - %s\n  ---\n  message: |\n    %s\n  ...\n'):format(count, name, message))
    -- The message goes to stderr too. run.sh shows the stderr of a failed file, and a person reads it more easily than YAML.
    io.stderr:write(('%s: %s: %s\n'):format(test_file, name, detail))
    table.insert(failures, name)
  end
end

function report.equals(name, got, expected)
  report.check(name, vim.deep_equal(got, expected), 'expected ' .. vim.inspect(expected) .. ', got ' .. vim.inspect(got))
end

function report.finish()
  io.stdout:write(('1..%d\n'):format(count))
  if #failures > 0 then
    vim.cmd('cquit')
  end
  vim.cmd('qall!')
end

return report
