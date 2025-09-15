return {
  "norcalli/nvim-colorizer.lua",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  opts = { { "*" }, { mode = "foreground" } },
  config = function(_, opts)
    require("colorizer").setup(unpack(opts))

    -- auto coloring
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("inobit_auto_colorizer", { clear = true }),
      pattern = {
        "html",
        "css",
        "scss",
        "less",
        "sass",
        "ts",
        "js",
        "tsx",
        "jsx",
      },
      callback = function(args)
        require("colorizer").attach_to_buffer(args.buf)
      end,
    })
  end,
}
