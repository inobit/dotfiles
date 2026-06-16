vim.filetype.add {
  pattern = {
    -- VS Code config files (JSONC)
    -- 注意：Neovim 会自动给 pattern 添加 ^ 和 $ 锚点，所以这里不需要写 $
    [".*/%.vscode/.*%.json"] = "jsonc",
    -- TypeScript/JavaScript project configs
    [".*tsconfig.*%.json"] = "jsonc",
    [".*jsconfig.*%.json"] = "jsonc",
    -- Deno config
    [".*deno%.jsonc?"] = "jsonc",
    -- Linter / Formatter configs
    [".*%.eslintrc%.json"] = "jsonc",
    [".*%.prettierrc%.json"] = "jsonc",
    -- dotenv
    [".env*"] = "dotenv",
  },
}
