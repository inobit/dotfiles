-- TS7 不提供编程 API，Vue SFC 的 TS 仍需 tsserver 体系，故 .vue 走 vue_ls + vtsls，
-- .ts/.tsx 由 tsc 接管（filetypes 收窄到 vue 以免两个 TS server 打架）。
-- globalPlugins 必须放 settings.vtsls.tsserver，放 init_options 不生效（上游注释有误）。
local vue_language_server_path = vim.fs.joinpath(
  vim.fn.stdpath "data",
  "mason",
  "packages",
  "vue-language-server",
  "node_modules",
  "@vue",
  "language-server"
)

return {
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vue_language_server_path,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
  },
  filetypes = { "vue" },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  on_attach = function(client)
    -- semantic tokens 自 @vue/language-server 3.0.2 起由 vue_ls 负责，避免重复高亮
    if vim.bo.filetype == "vue" then
      client.server_capabilities.semanticTokensProvider.full = false
    else
      client.server_capabilities.semanticTokensProvider.full = true
    end
  end,
}
