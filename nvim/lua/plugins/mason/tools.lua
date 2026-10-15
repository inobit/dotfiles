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
  -- JS/TS 三件套：tsc 提供智能（补全/跳转/类型诊断），oxlint 提供 lint，oxfmt 提供格式化
  "tsc", -- TypeScript 7 原生 LSP (tsc --lsp --stdio)，取代 ts_ls（tsserver 协议已被 TS7 移除）
  "oxlint", -- JS/TS linter (oxlint --lsp)，取代 eslint-lsp
  "oxfmt", -- JS/TS/CSS/Markdown/YAML/HTML 等 formatter (oxfmt --lsp)，oxfmt 不覆盖的 filetype 见下方 formatters
  "vue_ls", -- Vue SFC（mason 包名是 vue-language-server，由 mason/init.lua 自动映射）
  "vtsls", -- .vue 里的 TypeScript（TS7 无编程API，嵌入语言只能用 tsserver 体系），配置见 after/lsp/vtsls.lua
  "html",
  "cssls",
  "jsonls",
  "bashls", -- If shellcheck is installed, bash-language-server will automatically call it to provide linting
  -- sql 静态语法诊断 + 关键字补全（schema 智能由 sqmeow 提供）
  -- 注意：mason 装的 sqlls 1.7.1 会被 npm 解析出的新版 vscode-languageserver-protocol(3.18.x)/
  -- vscode-jsonrpc(9.x) 拖崩（ERR_PACKAGE_PATH_NOT_EXPORTED），需手动把 sqlls 包内这两个
  -- 嵌套依赖降级为 3.17.5 / 8.0.2；重装 sqlls 后需重新 pin
  "sqlls",
  "yamlls",
  "clangd",
  "emmet_ls",
  "marksman",
  "tombi",
  "docker_language_server",
}

---@type string[]
M.debugger_adapter = { "codelldb", "js-debug-adapter" }

---@type string[]
M.formatters = {
  "stylua", -- lua formatter
  "clang-format", -- c cpp formatter
  -- JS/TS/CSS/Markdown/YAML/HTML 等由 oxfmt LSP 接管，不在此列
  -- "prettier", -- 已移除：oxfmt 完全覆盖其filetype，格式化统一由 oxfmt LSP 负责
  "shfmt", -- shell formatter
  "xmlformatter", -- xml formatter
  "sql-formatter", --sql formatter
  "google-java-format", -- java formatter
}

---@type string[]
M.linters = {
  -- "mypy", -- python linter，已移除；python 诊断由 ruff + ty 两个 LSP 覆盖
  -- "eslint_d", -- 已由 oxlint LSP 取代
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
