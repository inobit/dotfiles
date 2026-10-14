-- vue_ls 只管 SFC 的 CSS/HTML 段，.vue 里的 TS 由它转发给 vtsls，故两者都需要。
-- 这里用 on_attach 而非 on_init：上游 lsp/vue_ls.lua 已定义 on_init（转发逻辑），
-- after/ 的同名键是整体替换而非合并，写 on_init 会把转发弄丢。
return {
  on_attach = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
