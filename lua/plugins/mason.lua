local servers = require('config.language_servers')

-- Installs the package of each language server that is missing.
-- It runs only when Neovim has a screen, so a headless Neovim, such as a test, never downloads a server.
local function install_missing()
  -- A test can fire UIEnter in a headless Neovim, so the check counts the screens.
  if #vim.api.nvim_list_uis() == 0 then
    return
  end
  local registry = require('mason-registry')
  registry.refresh(function()
    for _, name in vim.spairs(servers) do
      local server_package = registry.get_package(name)
      if not server_package:is_installed() then
        server_package:install()
      end
    end
  end)
end

return {
  {
    'mason-org/mason.nvim',
    -- mason puts the servers on PATH at setup, so it loads before the first file opens.
    lazy = false,
    config = function()
      require('mason').setup()
      vim.api.nvim_create_autocmd('UIEnter', {
        group = vim.api.nvim_create_augroup('MasonInstall', { clear = true }),
        once = true,
        callback = install_missing,
      })
    end,
  },
}
