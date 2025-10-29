vim.bo.textwidth = 120
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

vim.b.python_bin = require("lib.python").get_python_bin(vim.api.nvim_get_current_buf())

vim.lsp.config("pyright", {
  on_attach = function(client)
    require("lib.python").set_pyright_python_path(client, vim.b.python_bin)
  end,
})

---@return string
local function python_command_generator()
  local command
  if vim.fn.executable "uv" == 1 then
    command = "uv run " .. vim.fn.expand "%"
  else
    command = "python -u " .. vim.fn.expand "%"
  end
  return command
end

require("lib.run").register_run_keymap(python_command_generator, "<leader>rr")
