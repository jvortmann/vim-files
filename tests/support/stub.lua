local M = {}

local script = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/bin/record_call'

-- Makes path a link to the stub script. Each run of the stub adds its arguments, as one line, to the file calls in the
-- folder of path. On macOS, a link to a script that ran before starts at once, and a new script waits for a security scan.
function M.link(path)
  assert(vim.uv.fs_symlink(script, path))
end

-- Returns the lines that the script wrote to the file calls so far.
function M.calls(calls)
  return vim.uv.fs_stat(calls) and vim.fn.readfile(calls) or {}
end

return M
