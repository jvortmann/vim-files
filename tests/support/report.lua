local failures = {}

local report = {}

function report.check(name, ok, detail)
  if ok then
    print('ok   ' .. name)
  else
    print('FAIL ' .. name .. ': ' .. detail)
    table.insert(failures, name)
  end
end

function report.finish()
  io.stdout:write('\n')
  if #failures > 0 then
    vim.cmd('cquit')
  end
  vim.cmd('qall!')
end

return report
