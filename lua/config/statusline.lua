-- Custom statusline configuration
-- Display a warning if file encoding isn't utf-8
local function build_statusline()
  local statusline = {}

  -- Buffer number
  table.insert(statusline, '[%n]')

  -- Warning message start
  table.insert(statusline, ' %#warningmsg#')
  table.insert(statusline, '%*')

  -- Filename
  table.insert(statusline, '%f')

  -- Modified flag
  table.insert(statusline, '%m')

  -- Read only flag
  table.insert(statusline, '%r')

  -- Filetype
  table.insert(statusline, ' %y')

  -- File encoding (show if not utf-8)
  table.insert(statusline, "%{(&fenc!='utf-8'&&&fenc!='')?'['.&fenc.']':''}")

  -- Left/right separator
  table.insert(statusline, '%=')

  -- Show errors/warnings in status line
  table.insert(statusline, '%*')
  table.insert(statusline, '%#warningmsg#')
  table.insert(statusline, '%*')

  -- Left/right separator
  table.insert(statusline, '%=')

  -- Help file flag
  table.insert(statusline, '%h ')

  -- Cursor line,column
  table.insert(statusline, '[%l,%c]')

  -- Total lines
  table.insert(statusline, ' |%L lines|')

  -- Percent through file
  table.insert(statusline, ' %P')

  return table.concat(statusline, '')
end

vim.opt.statusline = build_statusline()