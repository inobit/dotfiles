return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },
    signs_staged = {
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
      local gitsigns = require "gitsigns"
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end
      -- Navigation
      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal { "]c", bang = true }
        else
          gitsigns.nav_hunk "next"
        end
      end, { desc = "Gitsigns: go to next hunk" })

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal { "[c", bang = true }
        else
          gitsigns.nav_hunk "prev"
        end
      end, { desc = "Gitsigns: go to prev hunk" })
        -- stylua: ignore start
        -- Actions
        -- reset is checkout stage to workspace
        map('n', '<leader>cs', gitsigns.stage_hunk,{ desc = "Gitsigns: stage hunk" })
        map('n', '<leader>cr', gitsigns.reset_hunk,{ desc = "Gitsigns: reset hunk" })
        map('v', '<leader>cs', function() gitsigns.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,{ desc = "Gitsigns: stage hunk" })
        map('v', '<leader>cr', function() gitsigns.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,{ desc = "Gitsigns: reset hunk" })
        map('n', '<leader>cS', gitsigns.stage_buffer,{ desc="Gitsigns: stage buffer" })
        map('n', '<leader>cu', gitsigns.undo_stage_hunk,{ desc="Gitsigns: undo stage buffer" })
        map('n', '<leader>cR', gitsigns.reset_buffer,{desc="Gitsigns: reset buffer"})
        map("n", "<leader>cp", function() gitsigns.preview_hunk_inline() end, { desc = "Gitsigns: hunk preview inline" })
        map("n", "<leader>cP", function() gitsigns.preview_hunk() end, { desc = "Gitsigns: hunk preview" })
        map("n", "<leader>cb", function() gitsigns.blame_line({ full = true }) end, { desc = "Gitsigns: Blame Line" })
        map("n", "<leader>cB", function() gitsigns.blame() end, { desc = "Gitsigns: Blame Buffer" })
        map("n", "<leader>ci", gitsigns.diffthis, { desc = "Gitsigns: diff with stage" })
        map("n", "<leader>cI", function() gitsigns.diffthis "~" end, { desc = "Gitsigns: diff with ~" })
        map("n", "<leader>ct", "<cmd>Gitsigns toggle_deleted<CR>", { desc = "Gitsigns: toggle deleted" })
        -- Text object
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>',{ desc = "Gitsigns: select hunk" })
      -- stylua: ignore end
    end,
  },
}
