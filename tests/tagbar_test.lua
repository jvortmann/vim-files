-- Run: nvim -i NONE --headless -c 'luafile tests/tagbar_test.lua' </dev/null
local tests_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
local report = dofile(tests_dir .. '/support/report.lua')
local keymaps = dofile(tests_dir .. '/support/keymaps.lua')
local check = report.check
local equals = report.equals
local child = dofile(tests_dir .. '/support/editor.lua')

equals('tagbar opens 60 columns wide', vim.g.tagbar_width, 60)

local expected_types = vim.fn.readfile(tests_dir .. '/fixtures/tagbar_types.txt')[1]
local types_match = vim.api.nvim_eval(
  "eval(" .. vim.fn.string(expected_types) .. ") ==# filter(copy(g:), 'v:key =~# \"^tagbar_type_\"')"
)
check(
  'tagbar gets the elixir, go, ruby, rust and scala types at startup',
  types_match == 1,
  'got ' .. vim.api.nvim_eval("string(filter(copy(g:), 'v:key =~# \"^tagbar_type_\"'))")
)

local undescribed = keymaps.undescribed({ '<M-i>', '<leader>ii', '<M-S-i>', '<leader>i', '<leader>i<space>' })
equals('every tagbar map has a description for which-key', undescribed, {})

local editor, job = child.start({ files = { tests_dir .. '/tagbar_test.lua' } })
vim.rpcrequest(editor, 'nvim_input', (vim.g.mapleader or '\\') .. 'i')
local open = vim.wait(5000, function()
  return vim.rpcrequest(editor, 'nvim_exec_lua', [[
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'tagbar' then
        return true
      end
    end
    return false
  ]], {})
end)
vim.fn.jobstop(job)
check('leader i opens tagbar in a new editor, where tagbar is not loaded yet', open, 'no tagbar window opened')

report.finish()
