return { -- Autoformat
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = {
    notify_on_error = false,
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
    formatters_by_ft = {
      lua = { "stylua" },
      python = {
        "black", --[[ "isort"  ]] -- 2个同时使用，会造成都生效，以至在最后加了2个空行，造成flake8 w391报错
      },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      sass = { "prettier" },
      less = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      json5 = { "prettier" },
      sh = { "shfmt" },
      xml = { "xmlformatter" },
      sql = { "sql-formatter" },
      yaml = { "yamlfmt" },
    },
  },
}
