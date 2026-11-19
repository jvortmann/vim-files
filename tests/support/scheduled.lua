-- Scheduled callbacks run in order, so wait for one that is scheduled after the pending ones.
return function()
  local ran = false
  vim.schedule(function() ran = true end)
  vim.wait(1000, function() return ran end)
end
