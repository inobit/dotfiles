vim.bo.textwidth = 120
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

local function cpp_command_generator()
  local output_filename = vim.fn.expand "%:t:r" .. ".out"
  return { "g++", "-g", "-Wall", vim.fn.expand "%", "-o", output_filename, "&&", "./" .. output_filename }
end

require("lib.run").register_run_keymap(cpp_command_generator, { cwd = vim.fn.getcwd() })
