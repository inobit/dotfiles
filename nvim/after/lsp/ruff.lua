local helper = require("lib.utils").lsp_format_helper "ruff"
return {
  on_attach = function(client, buf)
    -- Disable hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
    -- format on save
    helper(client, buf)
  end,
}
