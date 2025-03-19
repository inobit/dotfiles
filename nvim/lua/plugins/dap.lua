return {
  "mfussenegger/nvim-dap",
  keys = {
    {
      "<leader>dr",
      function()
        -- adapter and debugee config
        -- python config. need VIRTUAL_ENV
        if vim.bo.filetype == "python" then
          require "dap_set.python"
        elseif
          -- js config
          vim.tbl_contains(require "lib.js_based_languages", vim.bo.filetype)
        then
          require "dap_set.js"
        elseif vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
          require "dap_set.cpp"
        end
        -- run debug
        require("dap").continue()
      end,
      desc = "Debug: run",
    },
    -- stylua: ignore start
    { "<leader>ds", function() require("dap").terminate() end, desc = "Debug: stop", },
    { "<leader>dS",
      function()
        require("dap").disconnect({ restart = false, terminateDebuggee = nil }, function()
          require("dap").close()
        end)
      end,
      desc = "Debug: disconnect ",
    },
    { "<F7>", function() require("dap").step_into { askForTargets = true } end, desc = "Debug: step into", },
    { "<F8>", function() require("dap").step_over() end, desc = "Debug: step over", },
    { vim.fn.has "win32" == 1 and "<S-F8>" or "<S-F8>", function() require("dap").step_out() end, desc = "Debug: step out", },
    { "<F9>", function() require("dap").continue() end, desc = "Debug: continue" },
    { "<leader>dh", function() require("dap").run_to_cursor() end, desc = "Debug: run to cursor", },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Debug: run last", },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Debug: widgets", },
    { "<leader>dE", function() require("dap").repl.toggle() end, desc = "Debug: toggle repl", },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint", },
    { "<leader>do", function() require("dap").set_breakpoint(nil, nil, vim.fn.input "Log point message: ") end, desc = "Debug: set log breakpoint", },
    { "<leader>dc", function() require("dap").set_breakpoint(vim.fn.input "Condition: ", nil, nil) end, desc = "Debug: set condition breakpoint", },
    -- stylua: ignore end
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    { "theHamsta/nvim-dap-virtual-text", opts = {} },
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
    local persistence = require "dap_set.breakpoint_persistence"
    -- load run module
    -- require "dap_set.run"

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

    -- dapui setup
    ---@diagnostic disable-next-line: missing-fields
    require("dapui").setup {
      mappings = {
        edit = "e",
        expand = { "<CR>", "<2-LeftMouse>" },
        open = "o",
        remove = "d",
        repl = "r",
        --BUG: default is "t",but not work
        toggle = "s",
      },
    }

    -- dapui keymap
    local windows = {
      { "v", "1<C-W>w", "Scopes" },
      { "b", "2<C-W>w", "Breakpoints" },
      { "s", "3<C-W>w", "Stacks" },
      { "w", "4<C-W>w", "Watches" },
      { "h", "5<C-W>w", "App" },
      { "r", "6<C-W>w", "REPL" },
      { "c", "7<C-W>w", "Console" },
    }
    local function register_windows_navigation()
      vim.iter(windows):each(function(win)
        vim.keymap.set("n", "<leader><leader>" .. win[1], win[2], { desc = "Debug: goto " .. win[3] })
      end)
    end
    local function unset_windows_navigation()
      vim.iter(windows):each(function(win)
        pcall(vim.keymap.del, "n", "<leader><leader>" .. win[1])
      end)
    end

    -- stylua: ignore start
    vim.keymap.set("n", "<leader>B", function() persistence.toggle_breakpoints() end, { desc = "Debug: toggle breakpoints" })
    vim.keymap.set("n", "<leader>dpl", function() persistence.load_breakpoints() end, { desc = "Debug: load breakpoints" })
    vim.keymap.set("n", "<leader>dps", function() persistence.store_breakpoints(false) end, { desc = "Debug: store breakpoints" })
    vim.keymap.set("n", "<leader>dpc", function() persistence.store_breakpoints(true) end, { desc = "Debug: clear persistence  breakpoints" })
    vim.keymap.set("n", "<leader>td", function() require("dapui").toggle() end, { desc = "Debug: toggle dapui" })
    vim.keymap.set({ "n", "v" }, "<leader>de", function() require("dapui").eval() end, { desc = "Debug: eval" })
    vim.keymap.set({ "n", "v" }, "<leader>da", function() require("dapui").elements.watches.add() end, { desc = "Debug: add to watch" })
    vim.keymap.set({ "n", "v" }, "<leader>dd", function() require("dapui").elements.watches.remove() end, { desc = "Debug: remove from watch" })
    -- stylua: ignore end

    -- open and close dapui windows automatically
    dap.listeners.before.attach.dapui_config = function()
      register_windows_navigation()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      register_windows_navigation()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      unset_windows_navigation()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      unset_windows_navigation()
      dapui.close()
    end

    -- setup dap config by VsCode launch.json file
    local json = require "plenary.json"
    ---@diagnostic disable-next-line: duplicate-set-field
    require("dap.ext.vscode").json_decode = function(str)
      return vim.json.decode(json.json_strip_comments(str))
    end
  end,
}
