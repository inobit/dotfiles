return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = require("lspconfig").util.root_pattern(
    ".luarc.json",
    ".luarc.jsonc",
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
    ".git"
  ),
  -- capabilities = {},
  -- settings是针对lsp server本身的设置
  settings = {
    Lua = {
      format = {
        enable = false,
      },
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {
          "vim",
          "require",
        },
        libraryFiles = "Disable",
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = {
          vim.env.VIMRUNTIME,
          -- vim.fn.expand "$VIMRUNTIME/lua",
          -- vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
          -- vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
        },
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = "Both",
      },
      hover = {
        previewFields = 50, -- how many fields to show for a table
      },
      -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
      -- diagnostics = { disable = { 'missing-fields' } },
    },
  },
}
