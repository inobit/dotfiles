return {
  init_options = { hostInfo = "neovim" },
  cmd = { "typescript-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  single_file_support = true,
  settings = {
    completions = {
      completeFunctionCalls = true,
    },
    diagnostics = {
      -- https://github.com/microsoft/TypeScript/blob/main/src/compiler/diagnosticMessages.json
      ignoredCodes = { 80001, 80002 },
    },
  },
}
