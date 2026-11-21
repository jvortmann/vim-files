local M = {}

local registry = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h') .. '/mason_registry.lua'

-- Returns the arguments that make a child Neovim load the fake mason registry, so that it never downloads a server.
function M.args()
  return { '--cmd', ("lua package.preload['mason-registry'] = function() return dofile(%q) end"):format(registry) }
end

-- The Lua code that returns the calls that the fake registry received in the child.
M.calls = 'return _G.mason_registry_calls or {}'

return M
