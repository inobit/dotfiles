local dap = require "dap"

-- custom init for Java debugger
-- register dap adapter
-- require("jdtls").setup_dap { hotcodereplace = "auto", config_overrides = {} }
-- register dap configurations
dap.configurations.java = dap.configurations.java or {}
table.insert(dap.configurations.java, {
  type = "java",
  request = "attach",
  name = "Debug (Attach) - Remote",
  hostName = "127.0.0.1",
  port = 5005,
})
