vim.filetype.add {
  pattern = {
    -- VS Code config files (JSONC)
    [".*/%.vscode/.*%.json$"] = "jsonc",
    -- TypeScript/JavaScript project configs
    [".*tsconfig.*%.json$"] = "jsonc",
    [".*jsconfig.*%.json$"] = "jsonc",
    -- Deno config
    [".*deno%.jsonc?$"] = "jsonc",
    -- Linter / Formatter configs
    [".*%.eslintrc%.json$"] = "jsonc",
    [".*%.prettierrc%.json$"] = "jsonc",
    -- dotenv
    [".env*"] = "dotenv",
  },
}
