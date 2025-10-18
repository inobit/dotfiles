return {
  on_attach = function(client, _)
    -- Disable hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
  end,
}
