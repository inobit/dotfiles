---@class mason.Tools
---@field lsp_servers string[]
---@field debugger_adapter string[]
---@field formatters string[]
---@field linters string[]
M = {}

M.lsp_servers = {
  "lua_ls",
  "pyright",
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "bashls",
  "dockerls",
  "sqlls",
  "yamlls",
  "docker_compose_language_service",
  "clangd",
  "emmet_ls",
  "marksman",
}

M.debugger_adapter = { "codelldb" }

M.formatters = {
  "stylua", -- lua formatter
  "clang-format", -- c cpp formatter
  "black", -- python formatter
  "isort", -- python formatter
  "prettier", -- html,css,js,ts,json formatter
  "shfmt", -- shell formatter
  "xmlformatter", -- xml formatter
  "sql-formatter", --sql formatter
  "yamlfmt", -- yaml formatter
}

M.linters = {
  "ruff", -- python linter
  "mypy", -- python linter
  "eslint_d", -- js,ts linter
  "htmlhint", -- html linter
  "stylelint", -- css,scss,sass,less linter
  "jsonlint", -- json linter
  "shellcheck", -- shell linter
  "hadolint", -- dockerfile linter
  "sqlfluff", -- sql linter
  "yamllint", -- yaml linter
}

return M
