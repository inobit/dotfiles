-- See `:help gitsigns` to understand what the configuration keys do
-- Adds git related signs to the gutter, as well as utilities for managing changes
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    require("gitsigns").setup {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signcolumn = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
        virt_text_priority = 100,
      },
      current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Gitsigns: go to next hunk" })
        map("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, { expr = true, desc = "Gitsigns: go to prev hunk" })
        -- stylua: ignore start
        -- Actions
        -- reset is checkout stage to workspace
        map('n', '<leader>cs', gs.stage_hunk,{ desc = "Gitsigns: stage hunk" })
        map('n', '<leader>cr', gs.reset_hunk,{ desc = "Gitsigns: reset hunk" })
        map('v', '<leader>cs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end,{desc = "Gitsigns: stage hunk" })
        map('v', '<leader>cr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end,{desc = "Gitsigns: reset hunk" })
        map('n', '<leader>cS', gs.stage_buffer,{desc="Gitsigns: stage buffer"})
        map('n', '<leader>cu', gs.undo_stage_hunk,{desc="Gitsigns: undo stage buffer"})
        map('n', '<leader>cR', gs.reset_buffer,{desc="Gitsigns: reset buffer"})
        map("n", "<leader>cp", function() gs.preview_hunk_inline() end, { desc = "Gitsigns: hunk preview inline" })
        map("n", "<leader>cP", function() gs.preview_hunk() end, { desc = "Gitsigns: hunk preview" })
        map("n", "<leader>ci", gs.diffthis, { desc = "Gitsigns: diff with stage" })
        map("n", "<leader>cI", function() gs.diffthis "~" end, { desc = "Gitsigns: diff with ~" })
        map("n", "<leader>ct", "<cmd>Gitsigns toggle_deleted<CR>", { desc = "Gitsigns: toggle deleted" })
        -- Text object
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        -- stylua: ignore end
      end,
    }
  end,
}
