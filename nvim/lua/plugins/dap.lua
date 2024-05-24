return {
  "rcarriga/nvim-dap-ui",
  keys = { "<leader>rr", "<leader>db", "<leader>B" },
  dependencies = {
    "mfussenegger/nvim-dap",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
    {
      "mxsdev/nvim-dap-vscode-js",
      --手动安装在 ~/.dap
      --[[ dependencies = {
        "microsoft/vscode-js-debug",
        buid = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
      }, ]]
    },
  },
  config = function()
    -- dap client -launch/attach-> adapter(debugger) -launch/attach-> debuggee
    local dap, dapui = require "dap", require "dapui"
    -- load persistence module
    require "dap_set.breakpoint_persistence"
    -- load run module
    require "dap_set.run"

    -- setup sign color
    vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, fg = "#e51401" })
    vim.api.nvim_set_hl(0, "DapLogPoint", { ctermbg = 0, fg = "#61afef" })
    vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, fg = "#98c379", bg = "#31353f" })
    vim.fn.sign_define("DapBreakpoint", { text = "󰄯", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapBreakpointCondition", { text = "󰯲", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpoint" })
    vim.fn.sign_define("DapLogPoint", { text = "󰰍", texthl = "DapLogPoint" })
    vim.fn.sign_define(
      "DapStopped",
      { text = "󰐌", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" }
    )

    dap.defaults.fallback.terminal_win_cmd = "50vsplit new"
    -- show the debug console
    dap.defaults.fallback.console = "internalConsole"

    -- debug keymap
    function opts(desc)
      return { desc = desc, noremap = true, silent = true }
    end

    local js_based_languages = require "lib.js_based_languages"
    -- 启动时,根据filetype去dap.configurations中选择debuggee配置(类似launch.json),然后根据配置的type去dap.adapters下找对应的adapter配置
    vim.keymap.set("n", "<leader>dr", function()
      -- 将launch.json中的配置写入 dap.configurations,相同filetype且配置name(注意是name)相同则会覆盖已有的配置
      if vim.fn.filereadable ".vscode/launch.json" then
        local dap_vscode = require "dap.ext.vscode"
        if vim.bo.filetype == "python" then
          dap_vscode.load_launchjs(nil, {
            ["python"] = { "python" },
          })
        elseif vim.tbl_contains(js_based_languages, vim.bo.filetype) then
          dap_vscode.load_launchjs(nil, {
            -- js常用的adapters type
            ["pwa-node"] = js_based_languages,
            ["chrome"] = js_based_languages,
            ["pwa-chrome"] = js_based_languages,
          })
        end
      end
      dap.continue()
    end, opts "Debug run")

    -- stylua: ignore start
    vim.keymap.set("n", "<leader>ds", function() dap.terminate() end, opts "Debug stop")
    vim.keymap.set("n", "<leader>dS", function()
      dap.disconnect({ restart = false, terminateDebuggee = nil }, function()
        dap.close()
      end)
    end, opts "Debug disconnect ")
    vim.keymap.set("n", "<F7>", function() dap.step_into { askForTargets = true } end, opts "Debug step into")
    vim.keymap.set("n", "<F8>", function() dap.step_over() end, opts "Debug step over")
    vim.keymap.set("n", vim.fn.has "win32" == 1 and "<S-F8>" or "<S-F8>", function() dap.step_out() end, opts "Debug step out")
    vim.keymap.set("n", "<F9>", function() dap.continue() end, opts "Debug continue")
    vim.keymap.set("n", "<leader>dh", function() dap.run_to_cursor() end, opts "Debug run to cursor")
    vim.keymap.set("n", "<leader>db", function() dap.toggle_breakpoint() end, opts "Debug toggle breakpoint")
    vim.keymap.set("n", "<leader>B", function() toggle_breakpoints() end, opts "Debug toggle breakpoints")
    vim.keymap.set("n", "<leader>dl", function() load_breakpoints() end, opts "Debug load breakpoints")
    vim.keymap.set("n", "<leader>dp", function() store_breakpoints(false)   end, opts "Debug store breakpoints")
    vim.keymap.set("n", "<leader>dP", function() store_breakpoints(true)   end, opts "Debug clear persistence  breakpoints")
    vim.keymap.set("n", "<leader>do", function() dap.set_breakpoint(nil, nil, vim.fn.input "Log point message: ") end, opts "Debug set log breakpoint")
    vim.keymap.set("n", "<leader>dc", function() dap.set_breakpoint(vim.fn.input "Condition: ", nil, nil) end, opts "Debug set condition breakpoint")
    vim.keymap.set("n", "<leader>td", function() dapui.toggle() end, opts "Debug toggle dapui")
    vim.keymap.set({ "n", "x" }, "<leader>de", function() dapui.eval() end, opts "Debug eval expression")
    -- stylua: ignore start

    -- dapui setup
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      controls = {
        -- display controls in this element
        element = "repl",
        enabled = true,
        icons = {
          disconnect = "",
          pause = "",
          play = "",
          run_last = "",
          step_back = "",
          step_into = "",
          step_out = "",
          step_over = "",
          terminate = "",
        },
      },
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        repl = "r",
        toggle = "t",
      },
    }

    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
    -- virtual text setup
    require("nvim-dap-virtual-text").setup {}

    -- adapter and debugee config
    -- python config. need VIRTUAL_ENV
    if vim.bo.filetype == "python" then
      require "dap_set.python"
    elseif
      -- js config
      vim.tbl_contains(js_based_languages, vim.bo.filetype)
    then
      require "dap_set.js"
    end
  end,
}
