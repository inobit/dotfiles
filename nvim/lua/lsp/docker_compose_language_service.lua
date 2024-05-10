return {
  cmd = { "docker-compose-langserver", "--stdio" },
  filetypes = { "yaml.docker-compose" },
  root_dir = require("lspconfig").util.root_pattern(
    "docker-compose.yaml",
    "docker-compose.yml",
    "compose.yaml",
    "compose.yml"
  ),
  single_file_support = true,
}
