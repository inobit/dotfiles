local function setTheme(theme)
  vim.cmd.colorscheme(theme)
  vim.cmd.hi "Comment gui=none"
end
local theme = vim.g.theme or "catppuccin-frappe"
return { -- You can easily change to a different colorscheme.
  {
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    cond = string.find(theme, "tokyonight") ~= nil,
    opts = {},
    config = function()
      setTheme(theme)
    end,
  },
  {
    "navarasu/onedark.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    lazy = false,
    cond = string.find(theme, "onedark") ~= nil,
    config = function()
      require("onedark").setup {
        style = string.sub(theme, string.len "onedark-" + 1),
      }
      require("onedark").load()
    end,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    cond = string.find(theme, "catppuccin") ~= nil,
    config = function()
      setTheme(theme)
    end,
  },
  {
    "EdenEast/nightfox.nvim",
    priority = 1000,
    cond = string.find(theme, "nightfox") ~= nil,
    config = function()
      setTheme(string.sub(theme, string.len "nightfox-" + 1))
    end,
  },
  {
    "rose-pine/neovim",
    priority = 1000,
    cond = string.find(theme, "rose") ~= nil,
    config = function()
      setTheme(theme)
    end,
  },
}
