local dap = require "dap"
-- if not dap.adapters["codelldb"] then
dap.adapters["codelldb"] = {
  type = "server",
  -- host = "localhost",
  port = "${port}",
  executable = {
    command = "codelldb",
    -- command = os.getenv "HOME" .. "/.local/share/nvim/mason/bin/codelldb",
    args = {
      "--port",
      "${port}",
    },
  },
}
-- end
for _, lang in ipairs { "c", "cpp" } do
  dap.configurations[lang] = {
    {
      type = "codelldb",
      request = "launch",
      name = "Launch file",
      program = function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
    },
    {
      type = "codelldb",
      request = "attach",
      name = "Attach to process",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
    },
  }
end
