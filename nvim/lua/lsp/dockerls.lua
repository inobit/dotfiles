return {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_dir = require("lspconfig").util.root_pattern "Dockerfile",
  single_file_support = true,
}
