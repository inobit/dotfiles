---@class mason.Tools
M = {}

---@class mason.Environment
---@field lsps? string[]
---@field formatters? string[]
---@field linters? string[]
---@field debugger_adapter? string[]

---@type mason.Environment
local rust_env = {
  lsps = { "rust-analyzer", "bacon_ls" },
  -- formatters = { "rustfmt" }, - rustfmt is deprecated, install it from rustup
  linters = { "bacon" },
}

-- don't add jdtls here, it is configured by nvim-java
---@type string[]
M.lsp_servers = {
  "lua_ls",
  "ruff", -- python lsp
  -- "pyright", -- python lsp
  "ty", -- python lsp and type checker
  "ts_ls",
  "html",
  "cssls",
  "jsonls",
  "bashls", -- If shellcheck is installed, bash-language-server will automatically call it to provide linting
  "dockerls",
  -- "sqlls", -- disable, conflict with dbee-cmp
  "yamlls",
  "docker_compose_language_service",
  "clangd",
  "emmet_ls",
  "marksman",
  "eslint", --vsocde eslint, package name is eslint-lsp, need install eslint (global or local)
}

---@type string[]
M.debugger_adapter = { "codelldb", "js-debug-adapter" }

---@type string[]
M.formatters = {
  "stylua", -- lua formatter
  "clang-format", -- c cpp formatter
  "prettier", -- html,css,js,ts,json,markdown,yaml formatter
  "shfmt", -- shell formatter
  "xmlformatter", -- xml formatter
  "sql-formatter", --sql formatter
  "google-java-format", -- java formatter
}

---@type string[]
M.linters = {
  "mypy", -- python linter
  -- "eslint_d", -- use eslint-lsp
  "htmlhint", -- html linter
  "stylelint", -- css,scss,sass,less linter
  "shellcheck", -- shell linter
  "hadolint", -- dockerfile linter
  "sqlfluff", -- sql linter
  "yamllint", -- yaml linter
  "selene", -- lua linter
}

local enable_rust_env = not (vim.env.ENABLE_RUST_ENV == "false")
if enable_rust_env then
  M.lsp_servers = vim.list_extend(M.lsp_servers, rust_env.lsps or {})
  M.formatters = vim.list_extend(M.formatters, rust_env.formatters or {})
  M.linters = vim.list_extend(M.linters, rust_env.linters or {})
  M.debugger_adapter = vim.list_extend(M.debugger_adapter, rust_env.debugger_adapter or {})
end

return M
