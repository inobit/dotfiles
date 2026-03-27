return {
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
