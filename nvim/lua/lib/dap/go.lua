require("dap-go").setup {}

vim.keymap.set("n", "<leader>dgt", function()
  require("dap-go").debug_test()
end, { desc = "Debug: go test" })
vim.keymap.set("n", "<leader>dgl", function()
  require("dap-go").debug_last_test()
end, { desc = "Debug: go last test" })