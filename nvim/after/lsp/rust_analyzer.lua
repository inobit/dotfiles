return {
  settings = {
    ["rust-analyzer"] = {
      -- use bacon-ls instead
      checkOnSave = {
        enable = false,
      },
      diagnostics = {
        enable = false,
      },
    },
  },
}
