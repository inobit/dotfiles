vim.bo.textwidth = 120
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

---@return string
local function cpp_command_generator()
  local output_filename = vim.fn.expand "%:t:r" .. ".out"
  return string.format("g++ -g -Wall %s -o %s && ./%s", vim.fn.expand "%", output_filename, output_filename)
end

require("lib.run").register_run_keymap(cpp_command_generator, "<leader>rr")
