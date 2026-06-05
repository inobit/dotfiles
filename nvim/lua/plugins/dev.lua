return {
  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "Lazydev",
    dependencies = {
      { "Bilal2453/luvit-meta", lazy = true },
    },
    opts = {
      library = {
        { path = "luvit-meta/library", words = { "vim%.uv" } },
        { path = "plenary.nvim", words = { 'describe%(%"', "Job" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}
