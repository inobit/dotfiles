local dap = require "dap"
local Path = require "plenary.path"
local vscode = require "dap.ext.vscode"

local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

-- adapter config
local js_adapter_path = Path:new(
  vim.fn.stdpath "data",
  "mason",
  "packages",
  "js-debug-adapter",
  "js-debug",
  "src",
  "dapDebugServer.js"
).filename

local adapters = {
  "node",
  "chrome",
  "msedge",
}

for _, adapter in ipairs(adapters) do
  local pwa_adapter = "pwa-" .. adapter

  vscode.type_to_filetypes[adapter] = js_based_languages
  vscode.type_to_filetypes[pwa_adapter] = js_based_languages

  -- config pwa-node,pwa-chrome,pwa-msedge
  dap.adapters[pwa_adapter] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args = { js_adapter_path, "${port}" },
    },
  }
  -- support node, chrome, msedge (used by vscode)
  if not dap.adapters[adapter] then
    dap.adapters[adapter] = function(cb, config)
      config.type = pwa_adapter
      local nativeAdapter = dap.adapters[pwa_adapter]
      if type(nativeAdapter) == "function" then
        nativeAdapter(cb, config)
      else
        cb(nativeAdapter)
      end
    end
  end
end

-- debuggee config

for _, language in ipairs(js_based_languages) do
  dap.configurations[language] = {
    -- Debug single nodejs files
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      protocol = "inspector",
      skipFiles = { "<node_internals>/**", "node_modules/**" },
    },
    -- Debug nodejs processes (make sure to add --inspect when you run the process)
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
    },
    -- Debug web applications (client side)
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Launch & Debug Chrome",
      url = function()
        local co = coroutine.running()
        return coroutine.create(function()
          vim.ui.input({
            prompt = "Enter URL: ",
            default = "http://localhost:3000",
          }, function(url)
            if url == nil or url == "" then
              return
            else
              coroutine.resume(co, url)
            end
          end)
        end)
      end,
      -- webRoot = vim.fn.getcwd(),
      webRoot = "${workspaceFolder}",
      protocol = "inspector",
      sourceMaps = true,
      userDataDir = false,
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "Debug Jest Tests",
      -- trace = true, -- include debugger info
      runtimeExecutable = "node",
      runtimeArgs = {
        "./node_modules/jest/bin/jest.js",
        "--runInBand",
      },
      rootPath = "${workspaceFolder}",
      cwd = "${workspaceFolder}",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
    },
  }
end
