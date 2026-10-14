-- TS7 的 LSP 会声明 documentFormattingProvider，与 oxfmt 冲突。
-- 客户端摘掉 server_capabilities 后 supports_method 返回 false，vim.lsp.buf.format 自动跳过它。
return {
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
    client.server_capabilities.documentOnTypeFormattingProvider = false
  end,
  settings = {
    ["js/ts"] = {
      referencesCodeLens = { enabled = false },
      implementationsCodeLens = { enabled = false },
    },
  },
}
