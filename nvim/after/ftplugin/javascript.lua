require("lib.run").register_run_keymap(function()
  return "node " .. vim.fn.expand "%"
end, "<leader>rr")
