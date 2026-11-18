-- Source the plugin settings that are still VimScript.
-- The other settings sit in the `init` of the specs in lua/plugins/.
local settings_path = vim.fn.expand('~/.vim/conf/plugins/settings')
local settings_files = vim.fn.globpath(settings_path, '*.settings', false, true)

for _, setting_file in ipairs(settings_files) do
  vim.cmd('source ' .. setting_file)
end