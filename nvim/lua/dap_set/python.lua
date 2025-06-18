local dap_python = require "dap-python"
local dap = require "dap"

vim.keymap.set("n", "<leader>dtm", function()
  require("dap-python").test_method()
end, { noremap = true, silent = true, desc = "Debug python method test" })
vim.keymap.set("n", "<leader>dtc", function()
  require("dap-python").test_class()
end, { noremap = true, silent = true, desc = "Debug python class test" })

-- dap_python config adapters and debuggee
dap_python.setup "uv"

dap_python.resolve_python = function()
  return vim.b[vim.api.nvim_get_current_buf()].python_bin
end

-- custom config
table.insert(dap.configurations.python, {
  type = "python",
  request = "attach",
  name = "my attach remote",
  connect = function()
    local host = vim.fn.input "host [127.0.0.1]: "
    host = host ~= "" and host or "127.0.0.1"
    local port = tonumber(vim.fn.input "port [5678]: ") or 5678
    return { host = host, port = port }
  end,
  pathmappings = {
    {
      localroot = "${worspacefolder}",
      remoteroot = ".",
    },
  },
})
-- manual config
-- config how clients communicate with adapters
--[[ dap.adapters.python = function(cb, config)
  if config.request == "attach" then
    ---@diagnostic disable-next-line: undefined-field
    local port = (config.connect or config).port
    ---@diagnostic disable-next-line: undefined-field
    local host = (config.connect or config).host or "127.0.0.1"
    cb {
      type = "server",
      port = assert(port, "`connect.port` is required for a python `attach` configuration"),
      host = host,
      options = {
        source_filetype = "python",
      },
    }
  else
    cb {
      type = "executable",
      command = os.getenv "virtual_env" .. "/bin/python",
      args = { "-m", "debugpy.adapter" },
      options = {
        source_filetype = "python",
      },
    }
  end
end ]]
-- config how adapters communicate with debuggee

--[[ dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "my launch file",
    program = "${file}",
    justmycode = false,
    pythonpath = function()
      return os.getenv "virtual_env" .. "/bin/python"
    end,
  },
  {
    type = "python",
    request = "attach",
    name = "my attach remote",
    connect = function()
      local host = vim.fn.input "host [127.0.0.1]: "
      host = host ~= "" and host or "127.0.0.1"
      local port = tonumber(vim.fn.input "port [5678]: ") or 5678
      return { host = host, port = port }
    end,
    pathmappings = {
      {
        localroot = "${worspacefolder}",
        remoteroot = ".",
      },
    },
  },
} ]]
