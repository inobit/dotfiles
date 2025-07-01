return {
  {
    "Exafunction/codeium.nvim",
    event = { "VeryLazy" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      enable_cmp_source = "codeium" ~= vim.g.ai_inline_completion_engine,
      virtual_text = {
        enabled = "codeium" == vim.g.ai_inline_completion_engine,
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
  },
  {
    "supermaven-inc/supermaven-nvim",
    event = { "VeryLazy" },
    opts = {
      keymaps = {
        accept_suggestion = "<M-y>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-j>",
      },
      -- ignore_filetypes = {},
      disable_inline_completion = "supermaven" ~= vim.g.ai_inline_completion_engine,
    },
  },
  {
    "luozhiya/fittencode.nvim",
    event = { "VeryLazy" },
    opts = {
      inline_completion = {
        enabled = "fittencode" == vim.g.ai_inline_completion_engine,
      },
      source_completion = {
        enabled = "fittencode" ~= vim.g.ai_inline_completion_engine,
        engine = "cmp",
      },
      keymaps = {
        -- inline is disabled but inline keymaps are still available
        inline = "fittencode" == vim.g.ai_inline_completion_engine and {
          ["<M-y>"] = "accept_all_suggestions",
          ["<M-l>"] = "accept_line",
          ["<M-j>"] = "accept_word",
          ["<M-e>"] = "revoke_line",
          ["<M-k>"] = "revoke_word",
          ["<A-,>"] = "triggering_completion",
        } or nil,
      },
      completion_mode = "fittencode" ~= vim.g.ai_inline_completion_engine and "source" or "inline",
    },
  },
  -- avante
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
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
      { "<leader>ta", "<cmd>AvanteToggle<cr>", desc = "avante: toggle" },
      { "<leader>fa", "<cmd>AvanteFocus<cr>", desc = "avante: focus" },
      { "<leader>al", "<cmd>AvanteClear<cr>", desc = "avante: clear" },
    },
    opts = {
      provider = "openrouter-gemini-2.5-flash-pre",
      vendors = {
        ["siliconflow-deepseek-v3"] = {
          __inherited_from = "openai",
          api_key_name = "SILICONFLOW_API_KEY",
          endpoint = "https://api.siliconflow.cn/v1",
          model = "deepseek-ai/DeepSeek-V3",
          temperature = 0,
          max_tokens = 4096,
        },
        ["siliconflow-deepseek-r1"] = {
          __inherited_from = "openai",
          api_key_name = "SILICONFLOW_API_KEY",
          endpoint = "https://api.siliconflow.cn/v1",
          model = "deepseek-ai/DeepSeek-R1",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-claude3.7"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "anthropic/claude-3.7-sonnet",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-claude4"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "anthropic/claude-sonnet-4",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-gemini-2.5-flash-pre"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "google/gemini-2.5-flash-preview-05-20",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-gemini-2.5-pro"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "google/gemini-2.5-pro",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-deepseekv3:free"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "deepseek/deepseek-chat-v3-0324:free",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-deepseekv3"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "deepseek/deepseek-chat-v3-0324",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-deepseek-r1"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "deepseek/deepseek-r1-0528:free",
          temperature = 0,
          max_tokens = 4096,
        },
        ["openrouter-openai/gpt-4o-mini"] = {
          __inherited_from = "openai",
          api_key_name = "OPENROUTER_API_KEY",
          endpoint = "https://openrouter.ai/api/v1",
          model = "openai/gpt-4o-mini",
          temperature = 0,
          max_tokens = 4096,
        },
      },
    },
  },
}
