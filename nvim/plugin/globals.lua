vim.api.nvim_create_user_command("W", function()
  require("lib.utils").sudo_write()
end, { desc = "Write current buffer with sudo privileges" })
