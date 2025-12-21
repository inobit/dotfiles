return {
  {
    "Exafunction/windsurf.nvim",
    event = { "InsertEnter" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      enable_cmp_source = "codeium" ~= vim.g.ai_inline_completion_engine,
      virtual_text = {
        enabled = "codeium" == vim.g.ai_inline_completion_engine,
        filetypes = { bigfile = false, dap_repl = false, dotenv = false },
        key_bindings = {
          accept = "<M-y>",
          accept_line = "<M-l>",
          accept_word = "<M-j>",
          clear = "<M-e>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      workspace_root = {
        use_lsp = true,
        find_root = nil,
        paths = {
          ".bzr",
          ".git",
          ".hg",
          ".svn",
          "_FOSSIL_",
          "package.json",
        },
      },
    },
    config = function(_, opts)
      require("codeium").setup(opts)
    end,
  },
  {
    "supermaven-inc/supermaven-nvim",
    event = { "InsertEnter" },
    opts = {
      keymaps = {
        accept_suggestion = "<M-y>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-j>",
      },
      ignore_filetypes = { "bigfile", "dap-repl", "dotenv" },
      disable_inline_completion = "supermaven" ~= vim.g.ai_inline_completion_engine,
    },
  },
  -- avante
  {
    "yetone/avante.nvim",
    -- event = "VeryLazy",
    cond = false,
    version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- build = "make",
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false", -- for windows
    build = vim.fn.has "win32" == 1 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    dependencies = {
      -- "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    },
    keys = {
      { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "avante: toggle" },
      { "<leader>af", "<cmd>AvanteFocus<cr>", desc = "avante: focus" },
      { "<leader>al", "<cmd>AvanteClear<cr>", desc = "avante: clear" },
    },
    opts = function()
      ---@param model string
      ---@param temperature? number
      ---@param max_tokens? number
      ---@return table<string, any>
      ---@diagnostic disable-next-line: unused-function
      local function siliconflow_provider(model, temperature, max_tokens)
        return {
          __inherited_from = "openai",
          api_key_name = "SILICONFLOW_API_KEY",
          endpoint = "https://api.siliconflow.cn/v1",
          model = model,
          extra_request_body = { temperature = temperature or 0.4, max_tokens = max_tokens or 8192 },
        }
      end

      ---@param model string
      ---@param temperature? number
      ---@param max_tokens? number
      ---@return table<string, any>
      local function openrouter_provider(model, temperature, max_tokens)
        return {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = model,
          extra_request_body = { temperature = temperature or 0.4, max_tokens = max_tokens or 8192 },
        }
      end

      opts = {
        -- default provider
        provider = "openrouter-grok-code-fast",
        providers = {
          ["openrouter-claude4"] = openrouter_provider "anthropic/claude-sonnet-4.5",
          ["openrouter-gemini-2.5-flash"] = openrouter_provider "google/gemini-2.5-flash",
          ["openrouter-gemini-2.5-pro"] = openrouter_provider "google/gemini-2.5-pro",
          ["openrouter-grok-code-fast"] = openrouter_provider "x-ai/grok-code-fast-1",
        },
      }
      return opts
    end,
  },
}
