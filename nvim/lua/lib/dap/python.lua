local dap_python = require "dap-python"
local dap = require "dap"

vim.keymap.set("n", "<leader>dM", function()
  require("dap-python").test_method()
end, { noremap = true, silent = true, desc = "Debug python method test" })
vim.keymap.set("n", "<leader>dC", function()
  require("dap-python").test_class()
end, { noremap = true, silent = true, desc = "Debug python class test" })

-- dap_python config adapters and debuggee
dap_python.setup "uv"

dap_python.resolve_python = function()
  return vim.b.python_bin
end

local function resolve_script_python_path(script)
  local cmd = { "uv", "sync", "--script", script }
  local dry = { "--dry-run", "--output-format", "json" }
  local result = vim.system(vim.iter({ cmd, dry }):flatten():totable(), { text = true }):wait()
  local json = vim.json.decode(result.stdout:match "%b{}")
  local python = json.sync.environment.python.path
  if vim.fn.executable(python) ~= 1 then
    vim.system(cmd):wait()
  end
  return python
end

dap.adapters.uv_script = function(cb, config)
  local script = type(config.program) == "function" and config.program() or config.program
  local script_python_path = resolve_script_python_path(script)
  cb {
    type = "executable",
    command = "uv",
    args = {
      "run",
      "--with",
      "debugpy",
      "--python",
      script_python_path,
      "python",
      "-m",
      "debugpy.adapter",
    },
  }
end

table.insert(dap.configurations.python, {
  type = "uv_script",
  request = "launch",
  name = "file:script",
  program = "${file}",
  --args = {} -- args to program if needed
})

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
