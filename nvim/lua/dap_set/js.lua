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
      userDataDir = true,
    },

    -- How to debug a remote server in local chrome
    -- For example, in Debian:
    -- 1. sudo apt install chromium
    -- 2. Start remote debug mode: chromium --headless --remote-debugging-port=9222 --no-sandbox --remote-allow-origins='*' http://localhost:3000;
    -- 3. In the local machine:
    --    3.1 Set up port forwarding: ssh -N -L 922:localhost:9222 debian
    --    3.2 Start remote debug mode: Start-Process "chrome.exe" -ArgumentList "--remote-debugging-port=9222", "--user-data-dir=your_tmp_path"
    --    3.3 Open http://localhost:922 and get devtoolsFrontendUrl
    --    3.4 Open http://localhost:9222/{devtoolsFrontendUrl}
    --    3.5 You can see a nested window from the remote headless Chrome, and then open http://localhost:3000 in this window.
    -- 4. In the remote machine, use the following configuration to start the debug session.
    {
      type = "pwa-chrome",
      request = "attach",
      name = "Attach to Chrome",
      -- trace = true,
      port = 9222,
      webRoot = "${workspaceFolder}",
      protocol = "inspector",
      sourceMaps = true,
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
