return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },
  main = "ibl",
  opts = {
    scope = { enabled = false },
  },
}
