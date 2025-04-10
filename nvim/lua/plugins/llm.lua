return {
  {
    url = "https://gitee.com/inobit/llm.nvim.git",
    dev = vim.g.llm_dev or false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      -- stylua: ignore start
      { "<leader>mc", "<Cmd>LLM Chat<CR>", desc = "LLM: chat start" },
      { "<leader>ms", "<Cmd>LLM Sessions<CR>", desc = "LLM: select session" },
      { "<leader>mv", "<Cmd>LLM ChatServers<CR>", desc = "LLM: select chat server" },
      { "<leader>mt", "<Cmd>LLM TSServers<CR>", desc = "LLM: select translate server" },
      {
        "<leader>ts", function() require("inobit.llm.api").translate_in_buffer(true)  end, mode = { "n", "v" }, desc = "LLM: translate and replace",
      },
      {
        "<leader>tc", function() require("inobit.llm.api").translate_in_buffer(true, "Z2E_CAMEL") end, mode = { "n", "v" }, desc = "LLM: translate to VAR_CAMEL",
      },
      {
        "<leader>tu", function() require("inobit.llm.api").translate_in_buffer(true, "Z2E_UNDERLINE") end, mode = { "n", "v" }, desc = "LLM: translate to VAR_UNDERLINE",
      },
      {
        "<leader>tp", function() require("inobit.llm.api").translate_in_buffer(false)  end, mode = { "n", "v" }, desc = "LLM: translate and print",
      },
      -- stylua: ignore end
    },
    cmd = { "LLM", "TS" },
    name = "inobit-llm.nvim",
    main = "inobit.llm",
    opts = {
      servers = {
        {
          server = "SiliconFlow",
          base_url = "https://api.siliconflow.cn/v1/chat/completions",
          api_key_name = "SILICONFLOW_API_KEY",
          models = { "Qwen/Qwen2.5-Coder-7B-Instruct" },
          stream = true,
          multi_round = true,
          user_role = "user",
        },
        {
          server = "test-server",
          base_url = "http://localhost:8000/ai_stream",
          api_key_name = "TEST_API_KEY",
          models = { "test-model" },
          stream = true,
          multi_round = true,
        },
      },
      default_server = "SiliconFlow@Qwen/Qwen2.5-Coder-7B-Instruct",
      default_translate_server = "SiliconFlow@deepseek-ai/DeepSeek-V3",
      user_prompt = "~",
    },
  },
}
