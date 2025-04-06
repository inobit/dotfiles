return {
  {
    "Exafunction/codeium.nvim",
    event = { "BufEnter" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      enable_cmp_source = vim.g.ai_cmp,
      virtual_text = {
        enabled = not vim.g.ai_cmp,
        key_bindings = {
          accept = "<M-a>",
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
    opts = {
      keymaps = {
        accept_suggestion = "<M-a>",
        clear_suggestion = "<M-e>",
        accept_word = "<M-l>",
      },
      -- ignore_filetypes = {},
      disable_inline_completion = vim.g.ai_cmp,
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
      provider = "deepseek",
      vendors = {
        deepseek = {
          __inherited_from = "openai",
          api_key_name = "DEEPSEEK_API_KEY",
          endpoint = "https://api.siliconflow.cn/v1",
          model = "deepseek-ai/DeepSeek-R1",
          temperature = 0.6,
          max_tokens = 4096,
        },
        qwen = {
          __inherited_from = "openai",
          api_key_name = "DEEPSEEK_API_KEY", -- for free
          endpoint = "https://api.siliconflow.cn/v1",
          model = "Qwen/Qwen2.5-Coder-7B-Instruct",
          temperature = 0.7,
          max_tokens = 4096,
          disable_tools = true,
        },
      },
    },
  },
}
