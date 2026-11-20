return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = { add = { text = '▏' } },
      signs_staged = { add = { text = '▏' } },
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        local function selected_lines()
          return { vim.fn.line('.'), vim.fn.line('v') }
        end

        -- In a diff window, ]c and [c keep their built-in jumps between changes.
        local function jump(key, direction)
          return function()
            if vim.wo.diff then
              vim.cmd.normal({ vim.v.count1 .. key, bang = true })
            else
              gitsigns.nav_hunk(direction)
            end
          end
        end

        map('n', ']c', jump(']c', 'next'), 'Go to the next git hunk')
        map('n', '[c', jump('[c', 'prev'), 'Go to the previous git hunk')
        map('n', '<leader>gs', gitsigns.stage_hunk, 'Stage the git hunk')
        map('x', '<leader>gs', function() gitsigns.stage_hunk(selected_lines()) end, 'Stage the selected lines of the git hunk')
        map('n', '<leader>gr', gitsigns.reset_hunk, 'Reset the git hunk')
        map('x', '<leader>gr', function() gitsigns.reset_hunk(selected_lines()) end, 'Reset the selected lines of the git hunk')
        map('n', '<leader>gp', gitsigns.preview_hunk, 'Preview the git hunk')
        map('n', '<leader>gb', function() gitsigns.blame_line({ full = true }) end, 'Show the git blame of the line')
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk, 'Git hunk')
      end,
    },
  },
}
