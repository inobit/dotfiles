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
      { "<leader>ma", "<Cmd>LLM ChatServers<CR>", desc = "LLM: select chat server" },
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
    opts = function()
      local opts = {
        servers = {
          {
            server = "SiliconFlow",
            base_url = "https://api.siliconflow.cn/v1/chat/completions",
            api_key_name = "SILICONFLOW_API_KEY",
            models = {
              { model = "Qwen/Qwen2.5-Coder-7B-Instruct", max_tokens = 8192 },
              { model = "Qwen/Qwen2.5-Coder-32B-Instruct" },
              { model = "Qwen/Qwen3-235B-A22B" },
            },
            stream = true,
            temperature = 0.6,
            max_tokens = 4096,
            multi_round = true,
            user_role = "user",
          },
          {
            server = "OpenRouter",
            base_url = "https://openrouter.ai/api/v1/chat/completions",
            api_key_name = "OPENROUTER_API_KEY",
            models = {
              { model = "anthropic/claude-3.7-sonnet", temperature = 0 },
              { model = "anthropic/claude-sonnet-4", temperature = 0 },
              { model = "google/gemini-2.5-flash-preview-05-20", temperature = 0 },
              { model = "google/gemini-2.5-flash-lite-preview-06-17", temperature = 0 },
              { model = "google/gemini-2.5-pro", temperature = 0 },
              { model = "google/gemini-flash-1.5-8b", max_tokens = 8192, temperature = 0.6 },
              { model = "deepseek/deepseek-chat-v3-0324:free", max_tokens = 8192, temperature = 0.6 },
              { model = "deepseek/deepseek-chat-v3-0324", temperature = 0.6 },
              { model = "deepseek/deepseek-r1-0528:free", max_tokens = 8192, temperature = 0.6 },
              { model = "deepseek/deepseek-r1-0528", temperature = 0.6 },
              { model = "deepseek/deepseek-r1-0528-qwen3-8b:free", max_tokens = 8192, temperature = 0.6 },
              { model = "openai/gpt-4o-mini", temperature = 0 },
              { model = "qwen/qwen3-235b-a22b", temperature = 0.6 },
              { model = "qwen/qwen3-235b-a22b:free", max_tokens = 8192, temperature = 0.6 },
            },
            max_tokens = 4096,
            stream = true,
            multi_round = true,
            user_role = "user",
          },
        },
        default_server = "OpenRouter@deepseek/deepseek-chat-v3-0324:free",
        default_translate_server = vim.g.my_deeplx and "DeepL@DeepLX" or "OpenRouter@google/gemini-flash-1.5-8b",
        user_prompt = "~",
      }
      if vim.g.my_deeplx then
        table.insert(opts.servers, {
          server = "DeepL",
          server_type = "translate",
          models = {
            {
              model = "DeepLX",
              base_url = vim.g.my_deeplx_base_url,
              api_key_name = "DEEPLX_API_KEY",
            },
          },
        })
      end
      return opts
    end,
  },
}
