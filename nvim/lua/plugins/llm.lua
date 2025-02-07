return {
  {
    url = "https://gitee.com/inobit/llm.nvim.git",
    dev = vim.g.llm_dev or false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      -- stylua: ignore start
      { "<leader>mm", "<Cmd>LLM Chat<CR>", desc = "LLM: chat start" },
      { "<leader>ma", "<Cmd>LLM Auth<CR>", desc = "LLM: chat auth" },
      { "<leader>mn", "<Cmd>LLM New<CR>", desc = "LLM: chat new" },
      { "<leader>mx", "<Cmd>LLM Clear<CR>", desc = "LLM: chat clear(unsaved)" },
      { "<leader>mS", "<Cmd>LLM Save<CR>", desc = "LLM: chat  save" },
      { "<leader>ms", "<Cmd>LLM Sessions<CR>", desc = "LLM: select session" },
      { "<leader>md", "<Cmd>LLM Delete<CR>", desc = "LLM: delete session" },
      { "<leader>mr", "<Cmd>LLM Rename<CR>", desc = "LLM: rename session" },
      { "<leader>mv", "<Cmd>LLM Servers<CR>", desc = "LLM: select server" },
      -- stylua: ignore end
    },
    name = "inobit-llm.nvim",
    main = "inobit/llm",
    opts = {},
  },
}
