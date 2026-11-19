-- A bracket pairs only when no backslash precedes it and no word character follows it.
local bracket_neighbors = '^[^\\][^%w_]'

return {
  {
    'nvim-mini/mini.pairs',
    event = 'InsertEnter',
    opts = {
      mappings = {
        ['('] = { neigh_pattern = bracket_neighbors },
        ['['] = { neigh_pattern = bracket_neighbors },
        ['{'] = { neigh_pattern = bracket_neighbors },
      },
    },
  },
}
