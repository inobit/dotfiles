return {
  on_attach = function(client, buf)
    local group = vim.api.nvim_create_augroup("inobit_oxfmt_formatter", { clear = false })
    vim.api.nvim_clear_autocmds { group = group, buffer = buf }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      buffer = buf,
      desc = "Format on save by oxfmt",
      callback = function()
        vim.lsp.buf.format {
          async = false,
          filter = function(c)
            return c.name == "oxfmt"
          end,
        }
      end,
    })
  end,
}
