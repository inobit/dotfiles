return {
  "folke/trouble.nvim",
  keys = { "<leader>eb", "<leader>ew", "<leader>xx", "<leader>xq", "<leader>xl" },
  config = function()
    -- stylua: ignore start
    vim.keymap.set("n", "<leader>eb", function() require("trouble").toggle "document_diagnostics" end, { desc = "Document Diagnostics (Trouble)" })
    vim.keymap.set("n", "<leader>ew", function() require("trouble").toggle "workspace_diagnostics" end, { desc = "Workspace Diagnostics (Trouble)" })
    vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end, { desc = "trouble" })
    vim.keymap.set("n", "<leader>xq", function() require("trouble").toggle "quickfix" end, { desc = "Quickfix List (Trouble)" })
    vim.keymap.set("n", "<leader>xl", function() require("trouble").toggle "loclist" end, { desc = "Location List (Trouble)" })
    -- stylua: ignore end
  end,
}
