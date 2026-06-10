local helper = require("lib.utils").lsp_format_helper "tombi"
---@type vim.lsp.Config
return {
  cmd = { "tombi", "lsp" },
  filetypes = { "toml" },
  root_markers = { "tombi.toml", "pyproject.toml", ".git" },
  on_attach = function(client, buf)
    helper(client, buf)
  end,
}
