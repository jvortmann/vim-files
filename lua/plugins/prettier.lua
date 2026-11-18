return {
  {
    'prettier/vim-prettier',
    build = 'yarn install --frozen-lockfile --production',
    ft = { 'javascript', 'typescript', 'css', 'less', 'scss', 'json', 'ruby', 'markdown', 'yaml', 'html' },
    init = function()
      vim.g['prettier#autoformat_config_present'] = 1
      vim.g['prettier#autoformat_require_pragma'] = 0
      vim.g['prettier#exec_cmd_async'] = 1
      vim.g['prettier#quickfix_enabled'] = 0
    end,
  },
}
