-- Run: tests/run.sh tests/editorconfig_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local equals = report.equals

local function read_bytes(path)
  local file = assert(io.open(path, 'rb'))
  local bytes = file:read('a')
  file:close()
  return bytes
end

local function write_bytes(path, bytes)
  local file = assert(io.open(path, 'wb'))
  file:write(bytes)
  file:close()
end

-- Each case gets its own folder outside the repo, and an .editorconfig only when the case gives one.
-- With no bytes, the file does not exist yet, and the buffer gets one line.
local function after_write(bytes, editorconfig)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, 'p')
  local path = dir .. '/file.lua'
  local editorconfig_path = dir .. '/.editorconfig'
  if editorconfig then
    write_bytes(editorconfig_path, editorconfig)
  end
  if bytes then
    write_bytes(path, bytes)
  end
  local ok, result = pcall(function()
    vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
    if not bytes then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local a = 1' })
    end
    vim.cmd('silent write!')
    vim.cmd('bwipeout!')
    return read_bytes(path)
  end)
  os.remove(path)
  os.remove(editorconfig_path)
  os.remove(dir)
  return assert(ok and result, result)
end

local no_newline = 'local a = 1'
local with_newline = 'local a = 1\n'

equals('with no editorconfig, a write keeps a file with no final newline as it is', after_write(no_newline), no_newline)
equals('with no editorconfig, a new file ends with a newline', after_write(nil), with_newline)
equals(
  'an editorconfig with insert_final_newline = true adds the final newline',
  after_write(no_newline, '[*]\ninsert_final_newline = true\n'),
  with_newline
)

report.finish()
