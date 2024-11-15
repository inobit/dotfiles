return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  }, -- if you prefer nvim-web-devicons
  opts = {
    code = {
      sign = false,
      width = "full",
      -- right_pad = 1,
    },
    heading = {
      sign = false,
      -- icons = {},
    },
  },
  ft = { "markdown", "norg", "rmd", "org" },
}
