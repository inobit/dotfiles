return {
  {
    "inobit/llm.nvim",
    dev = vim.env.MY_LLM_DEV == "true",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      -- stylua: ignore start
      { "<leader>at", "<Cmd>LLM Toggle<CR>", desc = "LLM: chat toggle" },
      { "<leader>as", "<Cmd>LLM Sessions<CR>", desc = "LLM: select session" },
      { "<leader>ap", "<Cmd>LLM Providers<CR>", desc = "LLM: select provider" },
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
        -- 场景默认 Provider
        scenario_defaults = {
          chat = "OpenRouter",
          translate = vim.g.my_deeplx and "DeepL" or "OpenRouter",
        },
        providers = {
          --DeepL
          DeepL = {
            base_url = vim.g.my_deeplx and vim.g.my_deeplx_base_url or "https://api.deepl.com/v2/translate",
            api_key_name = false,
            default_model = "deepxl",
            fetch_models = false,
          },
        },

        -- UI 配置
        user_prompt = "~ ",
        -- chat_layout = "float",
        vsplit_win = {
          width_percentage = 0.4,
        },
      }

      return opts
    end,
  },
}
