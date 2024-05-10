return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  init_options = {
    provideFormatter = false,
  },
  root_dir = require("lspconfig").util.find_git_ancestor,
  single_file_support = true,
}
