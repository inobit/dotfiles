-- 注释插件,gcc gcb等等
return {
  "numToStr/Comment.nvim",
  event = "VeryLazy",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  opts = {},
  config = function()
    vim.g.skip_ts_context_commentstring_module = true
    ---@diagnostic disable-next-line: missing-fields
    require("ts_context_commentstring").setup {
      enable_autocmd = false,
    }
    ---@diagnostic disable-next-line: missing-fields
    require("Comment").setup {
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    }
  end,
}
