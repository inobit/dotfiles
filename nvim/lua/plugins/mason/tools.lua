---@class mason.Tools
M = {}

---@class mason.Environment
---@field lsps? string[]
---@field formatters? string[]
---@field linters? string[]
---@field debugger_adapter? string[]

---@type mason.Environment
local rust_env = {
  lsps = { "bacon_ls" }, -- rust-analyzer 用 rustup 安装，不再由 mason 管理
  -- formatters = { "rustfmt" }, - rustfmt is deprecated, install it from rustup
  linters = { "bacon" },
}

---@type mason.Environment
local go_env = {
  lsps = { "gopls" },
  linters = { "golangci-lint" },
  debugger_adapter = { "delve" },
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
  -- "sqlls", -- disable, conflict with dbee-cmp
  "yamlls",
  "clangd",
  "emmet_ls",
  "marksman",
  "eslint", --vsocde eslint, package name is eslint-lsp, need install eslint (global or local)
  "tombi",
  "docker_language_server"
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

local enable_go_env = not (vim.env.ENABLE_GO_ENV == "false")
if enable_go_env then
  M.lsp_servers = vim.list_extend(M.lsp_servers, go_env.lsps or {})
  M.formatters = vim.list_extend(M.formatters, go_env.formatters or {})
  M.linters = vim.list_extend(M.linters, go_env.linters or {})
  M.debugger_adapter = vim.list_extend(M.debugger_adapter, go_env.debugger_adapter or {})
end

return M
