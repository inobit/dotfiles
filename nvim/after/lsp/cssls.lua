local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
return {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  init_options = { provideFormatter = false }, -- needed to enable formatting capabilities
  single_file_support = true,
  settings = {
    css = { validate = true },
    scss = { validate = true },
    less = { validate = true },
  },
  capabilities = capabilities,
}
