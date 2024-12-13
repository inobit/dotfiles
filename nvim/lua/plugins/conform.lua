return { -- Autoformat
  "stevearc/conform.nvim",
  event = "VeryLazy",
  opts = {
    notify_on_error = false,
    format_on_save = {
      timeout_ms = 2500,
      lsp_fallback = true,
    },
    formatters_by_ft = {
      lua = { "stylua" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      python = {
        "black", --[[ "isort"  ]] -- 2个同时使用，会造成都生效，以至在最后加了2个空行，造成flake8 w391报错,插件BUG
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
      sql = { "sql_formatter" },
      yaml = { "yamlfmt" },
      markdown = { "prettier" },
    },
  },
  config = function(_, opts)
    local conform = require "conform"
    conform.setup(opts)

    conform.formatters.sql_formatter = {
      prepend_args = {
        "-c",
        vim.json.encode {
          language = "mysql",
          tabWidth = 2,
          keywordCase = "upper",
          dataTypeCase = "upper",
          functionCase = "upper",
          linesBetweenQueries = 2,
          paramTypes = { named = { ":" } },
        },
      },
    }

    -- clang-format global config
    local styles = vim.json.encode {
      BasedOnStyle = "LLVM",
      IndentPPDirectives = "AfterHash",
      IndentWidth = 4,
      AllowShortBlocksOnASingleLine = true,
      AllowShortCaseLabelsOnASingleLine = true,
      -- AllowShortIfStatementsOnASingleLine = true,
      AllowShortFunctionsOnASingleLine = "All",
      AlignAfterOpenBracket = "Align",
      BreakBeforeBraces = "Custom",
      BraceWrapping = {
        AfterClass = true,
        AfterControlStatement = true,
        AfterEnum = true,
        AfterFunction = true,
        AfterNamespace = true,
        AfterStruct = true,
        AfterUnion = true,
        AfterExternBlock = true,
        SplitEmptyFunction = false,
        SplitEmptyRecord = false,
        SplitEmptyNamespace = false,
      },
    }
    styles = styles:gsub('"', ""):gsub(":", ": ")
    conform.formatters["clang-format"] = {
      prepend_args = {
        -- use .clang-format file
        -- "-style=file",
        -- use command line arguments
        "-style=" .. styles,
      },
    }
  end,
}
