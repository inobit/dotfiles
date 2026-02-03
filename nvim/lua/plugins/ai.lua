return {
  {
    "Exafunction/windsurf.nvim",
    event = { "InsertEnter" },
    cond = not vim.g.disable_ai_completion,
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
    cond = not vim.g.disable_ai_completion,
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
}
