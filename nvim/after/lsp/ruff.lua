return {
  on_attach = function(client, buf)
    -- Disable hover in favor of Pyright
    client.server_capabilities.hoverProvider = false
    -- format on save
    local group = vim.api.nvim_create_augroup("inobit_ruff_formatter", { clear = false }) -- don't clear autocmds
    vim.api.nvim_clear_autocmds { group = group, buffer = buf }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      buffer = buf,
      desc = "Format python with ruff on save",
      callback = function()
        vim.lsp.buf.format { async = false }
      end,
    })
  end,
}
