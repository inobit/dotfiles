return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  }, -- if you prefer nvim-web-devicons
  opts = {
    -- Vim modes that will show a rendered view of the markdown file
    -- All other modes will be unaffected by this plugin
    -- render_modes = { "n", "c" },
    render_modes = true,
    code = {
      sign = false,
      width = "full",
      -- right_pad = 1,
    },
    heading = {
      sign = false,
      icons = {},
    },
    html = {
      enabled = true,
      comment = { conceal = false },
    },
  },
  ft = { "markdown", "norg", "rmd", "org", vim.g.inobit_filetype },
}
