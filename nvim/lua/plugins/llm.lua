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
      { "<leader>mt", "<Cmd>LLM ShutDown<CR>", desc = "LLM: chat shutdown" },
      { "<leader>ma", "<Cmd>LLM Auth<CR>", desc = "LLM: chat auth" },
      { "<leader>mn", "<Cmd>LLM New<CR>", desc = "LLM: chat new" },
      { "<leader>mx", "<Cmd>LLM Clear<CR>", desc = "LLM: chat clear(unsaved)" },
      { "<leader>mS", "<Cmd>LLM Save<CR>", desc = "LLM: chat  save" },
      { "<leader>ms", "<Cmd>LLM Sessions<CR>", desc = "LLM: select session" },
      { "<leader>md", "<Cmd>LLM Delete<CR>", desc = "LLM: delete session" },
      { "<leader>mr", "<Cmd>LLM Rename<CR>", desc = "LLM: rename session" },
      { "<leader>mv", "<Cmd>LLM Servers<CR>", desc = "LLM: select server" },
      {
        "<leader>tsz", function() require("inobit.llm.translate").translate_and_repalce "E2Z" end, mode = { "n", "v" }, desc = "LLM: translate to ZH",
      },
      {
        "<leader>tse", function() require("inobit.llm.translate").translate_and_repalce "Z2E" end, mode = { "n", "v" }, desc = "LLM: translate to EN",
      },
      {
        "<leader>tsc", function() require("inobit.llm.translate").translate_and_repalce "Z2E_CAMEL" end, mode = { "n", "v" }, desc = "LLM: translate to VAR_CAMEL",
      },
      {
        "<leader>tsu", function() require("inobit.llm.translate").translate_and_repalce "Z2E_UNDERLINE" end, mode = { "n", "v" }, desc = "LLM: translate to VAR_UNDERLINE", },
      -- stylua: ignore end
    },
    cmd = { "LLM", "TS" },
    name = "inobit-llm.nvim",
    main = "inobit/llm",
    opts = {
      servers = {
        {
          server = "Qwen",
          base_url = "https://api.siliconflow.cn/v1",
          model = "Qwen/Qwen2.5-Coder-7B-Instruct",
          stream = true,
          multi_round = true,
          user_role = "user",
        },
      },
    },
  },
}
