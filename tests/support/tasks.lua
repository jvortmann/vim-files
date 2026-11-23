-- Runs the cases of a test file at the same time, so that their waits overlap. A case is a function that waits with
-- M.wait. While one case waits, the others run.
local M = {}

local function now()
  return vim.uv.hrtime() / 1e6
end

-- Waits until condition returns true, for up to timeout milliseconds. With no condition, it waits the whole timeout.
-- Returns whether the condition became true. Call it only inside a case of M.all.
function M.wait(timeout, condition)
  return coroutine.yield({ deadline = now() + timeout, condition = condition })
end

-- Runs the cases at the same time until each one ends. Returns the value of each case, in the order of the cases.
function M.all(cases)
  local results, pending = {}, {}
  local function resume(i, case, ...)
    local ok, value = coroutine.resume(case, ...)
    if not ok then
      error(debug.traceback(case, value), 0)
    end
    if coroutine.status(case) == 'dead' then
      results[i], pending[i] = value, nil
    else
      pending[i] = { case = case, wait = value }
    end
  end
  for i, case in ipairs(cases) do
    resume(i, coroutine.create(case))
  end
  while next(pending) do
    vim.wait(10)
    for i, entry in pairs(pending) do
      local met = entry.wait.condition ~= nil and entry.wait.condition() == true
      if met or now() >= entry.wait.deadline then
        resume(i, entry.case, met)
      end
    end
  end
  return results
end

return M
