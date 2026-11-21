-- A stand-in for the mason-registry module, which a child Neovim loads in place of the real one.
-- It downloads nothing. Each call to refresh or install adds a line to _G.mason_registry_calls.
-- The packages in vim.g.fake_mason_installed count as installed.
_G.mason_registry_calls = _G.mason_registry_calls or {}

-- mason.setup adds its registries to these lists.
local M = { sources = { append = function() end }, system_sources = { append = function() end } }

function M.refresh(callback)
  table.insert(_G.mason_registry_calls, 'refresh')
  callback(true, {})
end

function M.get_package(name)
  return {
    name = name,
    is_installed = function() return vim.tbl_contains(vim.g.fake_mason_installed or {}, name) end,
    install = function() table.insert(_G.mason_registry_calls, 'install ' .. name) end,
  }
end

return M
