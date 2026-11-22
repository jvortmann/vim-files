-- Parts of the statusline that lualine does not give
local M = {}

-- The filetypes where airline counts words, and gitcommit
local text_filetypes = {
  'asciidoc', 'gitcommit', 'help', 'mail', 'markdown', 'nroff', 'org', 'plaintex', 'rmd', 'rst', 'tex', 'text',
}

-- The checks of airline: trailing whitespace, and an indent that mixes tabs and spaces
local whitespace_checks = {
  { pattern = [[\s$]], format = '[%d]trailing' },
  { pattern = [[\v(^\t+ +)|(^ +\t+)]], format = '[%d]mixed-indent' },
}

-- The whitespace warning of each buffer. A scan reads every line, so a redraw reuses it until an event clears it.
local whitespace_by_buffer = {}
local find_whitespace

function M.setup()
  vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'BufWipeout' }, {
    group = vim.api.nvim_create_augroup('config_statusline_whitespace', { clear = true }),
    callback = function(args)
      whitespace_by_buffer[args.buf] = nil
    end,
  })
end

function M.spell()
  if not vim.wo.spell then
    return ''
  end
  return 'SPELL [' .. vim.bo.spelllang:upper():gsub(',', '/') .. ']'
end

function M.whitespace()
  local buf = vim.api.nvim_get_current_buf()
  if whitespace_by_buffer[buf] == nil then
    whitespace_by_buffer[buf] = find_whitespace(buf)
  end
  return whitespace_by_buffer[buf]
end

function M.words()
  if not vim.tbl_contains(text_filetypes, vim.bo.filetype) then
    return ''
  end
  local count = vim.fn.wordcount()
  return (count.visual_words or count.words) .. ' words'
end

function M.encoding()
  local missing_eol = (vim.bo.endofline or vim.bo.fixendofline) and '' or '[!EOL]'
  local encoding = vim.bo.fileencoding ~= '' and vim.bo.fileencoding or vim.o.encoding
  local text = encoding .. missing_eol .. '[' .. vim.bo.fileformat .. ']'
  return text == 'utf-8[unix]' and '' or text
end

function find_whitespace(buf)
  if not vim.bo[buf].modifiable then
    return ''
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local found = {}
  for _, check in ipairs(whitespace_checks) do
    local index = vim.fn.match(lines, check.pattern)
    if index >= 0 then
      table.insert(found, check.format:format(index + 1))
    end
  end
  return table.concat(found, ' ')
end

return M
