return {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  root_dir = require("lspconfig").util.root_pattern ".sqllsrc.json",
  settings = {},
}
