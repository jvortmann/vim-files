-- Load all shortcut files
local shortcuts_path = vim.fn.expand('~/.vim/conf/shortcuts')
local shortcut_files = vim.fn.globpath(shortcuts_path, '*.shortcuts', false, true)

for _, shortcut_file in ipairs(shortcut_files) do
  vim.cmd('source ' .. shortcut_file)
end