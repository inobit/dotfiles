local plugins_path = vim.fn.stdpath "config" .. "/lua/plugins/inobit"
return {
  {
    dir = plugins_path .. "/llm",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      -- stylua: ignore start
      { "<leader>mm", "<Cmd>LLM Chat<CR>", desc = "LLM: chat start" },
      { "<leader>ma", "<Cmd>LLM Auth<CR>", desc = "LLM: chat auth" },
      { "<leader>mn", "<Cmd>LLM New<CR>", desc = "LLM: chat new" },
      { "<leader>ms", "<Cmd>LLM Sessions<CR>", desc = "LLM: chat sessions" },
      { "<leader>ml", "<Cmd>LLM Clear<CR>", desc = "LLM: chat clear" },
      { "<leader>mS", "<Cmd>LLM Save<CR>", desc = "LLM: chat  save" },
      { "<leader>md", "<Cmd>LLM Delete<CR>", desc = "LLM: delete session" },
      -- stylua: ignore end
    },
    opts = {},
  },
}
