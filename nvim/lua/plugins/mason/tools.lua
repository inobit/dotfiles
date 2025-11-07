---@class mason.Tools
M = {}

-- don't add jdtls here, it is configured by nvim-java
---@type string[]
M.lsp_servers = {
  "lua_ls",
  "ruff", -- python lsp
  "pyright", -- python lsp
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
  "rust_analyzer", -- rust lsp
  "bacon_ls", -- a lsp server wrapper for rust bacon
}

---@type string[]
M.debugger_adapter = { "codelldb", "js-debug-adapter" }

---@type string[]
M.formatters = {
  "stylua", -- lua formatter
  "clang-format", -- c cpp formatter
  "black", -- python formatter
  "isort", -- python formatter
  "prettier", -- html,css,js,ts,json,markdown,yaml formatter
  "shfmt", -- shell formatter
  "xmlformatter", -- xml formatter
  "sql-formatter", --sql formatter
  "google-java-format", -- java formatter
  --  "rustfmt", -- , rustfmt should now be installed via rustup.
}

---@type string[]
M.linters = {
  -- "ruff", -- python linter(lsp)
  "mypy", -- python linter
  -- "eslint_d", -- use eslint-lsp
  "htmlhint", -- html linter
  "stylelint", -- css,scss,sass,less linter
  "shellcheck", -- shell linter
  "hadolint", -- dockerfile linter
  "sqlfluff", -- sql linter
  "yamllint", -- yaml linter
  "selene", -- lua linter
  "bacon", -- rust linter ,used by bacon-ls
}

return M
