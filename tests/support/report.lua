local failures = {}
local count = 0

local report = {}

function report.check(name, ok, detail)
  count = count + 1
  if ok then
    io.stdout:write(('ok %d - %s\n'):format(count, name))
  else
    local message = detail:gsub('\n', '\n    ')
    io.stdout:write(('not ok %d - %s\n  ---\n  message: |\n    %s\n  ...\n'):format(count, name, message))
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
