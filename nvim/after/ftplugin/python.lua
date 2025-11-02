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

local function get_root_dir()
  return require("lib.utils").get_root_dir(0, "pyproject.toml") or vim.fn.getcwd()
end

---@return string
local function python_command_generator()
  local command
  local project = require("lib.utils").get_root_dir(0, "pyproject.toml")
  local file = project and "main.py" or vim.fn.expand "%"
  if vim.fn.executable "uv" == 1 then
    command = "uv run"
  else
    command = "python -u"
  end
  return command .. " " .. file
end

require("lib.run").register_run_keymap(python_command_generator, { cwd = get_root_dir })
