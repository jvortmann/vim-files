return {
  { -- github gist
    'mattn/gist-vim',
    init = function()
      -- set gist to be private by default
      vim.g.gist_post_private = 1
      -- show private gists on show
      vim.g.gist_show_privates = 1
    end,
  },
  { 'mattn/webapi-vim' }, -- gist dependency
}
