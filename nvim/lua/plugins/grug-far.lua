return {
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = "GrugFar",
  keys = {
    {
      "<leader>sx",
      function()
        local grug = require "grug-far"
        local ext = vim.bo.buftype == "" and vim.fn.expand "%:e"
        grug.open {
          transient = true, -- temporary buffer
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil, -- Pre-populated file filters
          },
        }
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
  },
}
