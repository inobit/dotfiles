return {
  "cosmicbuffalo/eyeliner.nvim",
  -- keys = { "f", "F", "t", "T" },
  config = function()
    require("eyeliner").setup {
      dim = false, -- dim all other characters if set to true (recommended!)
      disabled_filetypes = {
        "dashboard",
        "snacks_dashboard",
        "dapui_breakpoints",
        "dapui_stacks",
        "dapui_scopes",
        "dapui_watches",
        "dap-repl",
      },
    }
  end,
}
