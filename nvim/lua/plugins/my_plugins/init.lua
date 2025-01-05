local plugins_path = vim.fn.stdpath "config" .. "/lua/plugins/my_plugins"
return {
  {
    dir = plugins_path .. "/llm",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>ms", "<Cmd>LLM Chat<CR>", desc = "LLM: chat start" },
    },
    opts = {},
  },
}
