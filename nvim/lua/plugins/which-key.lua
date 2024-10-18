return { -- Useful plugin to show you pending keybinds.
  "folke/which-key.nvim",
  event = "VeryLazy", -- Sets the loading event to 'VimEnter'
  opts = {
    defaults = {},
    spec = {
      {
        mode = { "n", "v" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "gitsigns" },
        { "<leader>d", group = "debug" },
        { "<leader>r", group = "rename" },
        { "<leader>s", group = "search" },
        { "<leader>x", group = "diagnostics/quickfix", icon = { icon = "󱖫 ", color = "green" } },
        { "[", group = "prev" },
        { "]", group = "next" },
      },
    },
    layout = {
      height = { min = 4, max = 25 }, -- min and max height of the columns
      width = { min = 20, max = 60 }, -- min and max width of the columns
      spacing = 8, -- spacing between columns
      align = "left", -- align columns left, center or right
    },
  },
}
