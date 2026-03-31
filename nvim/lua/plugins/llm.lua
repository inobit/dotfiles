return {
  {
    url = "https://gitee.com/inobit/llm.nvim.git",
    dev = vim.env.MY_LLM_DEV == "true",
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
            server = "OpenRouter",
            base_url = "https://openrouter.ai/api/v1/chat/completions",
            api_key_name = "OPENROUTER_API_KEY",
            models = {
              { model = "anthropic/claude-opus-4.5", temperature = 0.4 },
              { model = "openai/gpt-5.2", temperature = 0.4 },
              { model = "google/gemini-3-pro-preview", temperature = 0.4 },
              { model = "google/gemini-2.5-flash", temperature = 0.4 },
              { model = "google/gemini-2.0-flash-001", max_tokens = 8192, temperature = 0.6 },
              { model = "x-ai/grok-code-fast-1", max_tokens = 8192, temperature = 0.6 },
            },
            max_tokens = 4096,
            stream = true,
            multi_round = true,
            user_role = "user",
          },
          {
            server = "nvidia",
            base_url = "https://integrate.api.nvidia.com/v1/chat/completions",
            api_key_name = "NVIDIA_API_KEY",
            models = {
              { model = "minimaxai/minimax-m2", max_tokens = 8192, temperature = 0.6 },
              { model = "z-ai/glm4.7", max_tokens = 8192, temperature = 0.6 },
            },
            temperature = 1,
            stream = true,
            multi_round = true,
            user_role = "user",
          },
        },
        default_server = "nvidia@minimaxai/minimax-m2",
        default_translate_server = vim.g.my_deeplx and "DeepL@DeepLX" or "OpenRouter@google/gemini-2.0-flash-001",
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
