local M = {}

-- Writes an executable script at path. Each run of the script adds its arguments, as one line, to the file calls.
function M.write(path, calls)
  vim.fn.writefile({ '#!/bin/sh', 'printf "%s\\n" "$*" >> "' .. calls .. '"' }, path)
  vim.fn.setfperm(path, 'rwxr-xr-x')
end

-- Returns the lines that the script wrote to the file calls so far.
function M.calls(calls)
  return vim.uv.fs_stat(calls) and vim.fn.readfile(calls) or {}
end

return M
