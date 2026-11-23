-- Run: tests/run.sh tests/highlight-colors_test.lua
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local check = report.check

local function open(extension, lines)
  local path = vim.fn.tempname() .. extension
  vim.fn.writefile(lines, path)
  vim.cmd('silent edit ' .. vim.fn.fnameescape(path))
end

-- The colors of every syntax and extmark highlight at a position, whatever plugin draws them.
local function colors_at(row, col)
  local found = {}
  local pos = vim.inspect_pos(0, row, col)
  for _, item in ipairs(vim.list_extend(vim.deepcopy(pos.syntax), pos.extmarks)) do
    local group = item.hl_group_link or item.hl_group or (item.opts and item.opts.hl_group)
    if group then
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      for _, key in ipairs({ 'bg', 'fg' }) do
        if hl[key] then
          found[hl[key]] = true
        end
      end
    end
  end
  return found
end

local function has_color(row, col, color)
  return vim.wait(1000, function() return colors_at(row, col)[color] == true end, 20)
end

open('.css', { 'a {', '  color: #ff0000;', '}' })
-- This wait makes sure the plugin is active, so the lua check below can fail.
assert(has_color(1, 9, 0xff0000), 'highlight-colors did not color the css buffer')

open('.lua', { 'local red = "#ff0000"' })
vim.wait(300)
check(
  'a color code in a lua buffer shows no color, also after a css buffer',
  colors_at(0, 13)[0xff0000] == nil,
  'the lua buffer shows #ff0000'
)

report.finish()
