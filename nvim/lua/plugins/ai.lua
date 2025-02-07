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
          accept = "<M-l>",
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
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionCmd", "CodeCompanionActions" },
    config = function()
      require("codecompanion").setup {
        adapters = {
          deepseek = function()
            return require("codecompanion.adapters").extend("deepseek", {
              env = {
                api_key = vim.g.deepseek_fim_api_key,
              },
            })
          end,
        },
        strategies = {
          chat = { adapter = "deepseek" },
          inline = { adapter = "deepseek" },
          agent = { adapter = "deepseek" },
        },
      }
    end,
  },
}
