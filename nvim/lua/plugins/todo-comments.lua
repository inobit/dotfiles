-- Highlight todo, notes, etc in comments
-- usage: TODO/FIX/NOTE/HACK/TEST/WARN/PERF  .. :
return {
  "folke/todo-comments.nvim",
  keys = { "[t", "]t" },
  cmd = { "TodoTrouble", "TodoTelescope" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = { signs = false },
  config = function(_, opts)
    require("todo-comments").setup(opts)

    -- keymap
    -- stylua: ignore start
    vim.keymap.set("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next todo comment" })
    vim.keymap.set("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Previous todo comment" })
    vim.keymap.set("n", "<leader>st", "<Cmd>TodoTelescope<CR>", { desc = "Todo" })
    vim.keymap.set("n", "<leader>sT", "<Cmd>TodoTelescope keywords=TODO,FIX,FIXME<CR>", { desc = "Todo/Fix/FixMe" })
    vim.keymap.set("n", "<leader>xt", "<Cmd>TodoTrouble<CR>", { desc = "Todo" })
    vim.keymap.set("n", "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", { desc = "Todo/Fix/FixMe" })
    -- stylua: ignore end
  end,
}
