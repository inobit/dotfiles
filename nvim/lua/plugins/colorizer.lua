return {
  "norcalli/nvim-colorizer.lua",
  event = { "VeryLazy" },
  config = function()
    require("colorizer").setup({
      "*",
    }, { css = true, mode = "foreground" })
  end,
}
