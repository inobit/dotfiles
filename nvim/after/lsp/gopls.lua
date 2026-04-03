return {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
        ST1000 = false, -- Incorrect or missing package comment
      },
      staticcheck = true,
      gofumpt = true,
      completeUnimported = true,
      usePlaceholders = true,
    },
  },
  on_attach = function(_, buf)
    -- format and organize imports on save
    local group = vim.api.nvim_create_augroup("inobit_gopls_formatter", { clear = false })
    vim.api.nvim_clear_autocmds { group = group, buffer = buf }
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      buffer = buf,
      desc = "Format Go with gopls and organize imports on save",
      callback = function()
        -- organize imports
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(buf, "textDocument/codeAction", params, 3000)
        for cid, res in pairs(result or {}) do
          for _, r in pairs(res.result or {}) do
            if r.edit then
              local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
              vim.lsp.util.apply_workspace_edit(r.edit, enc)
            end
          end
        end
        -- format
        vim.lsp.buf.format { async = false }
      end,
    })
  end,
}
