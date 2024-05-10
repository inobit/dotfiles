return { -- Useful plugin to show you pending keybinds.
  "folke/which-key.nvim",
  event = "VimEnter", -- Sets the loading event to 'VimEnter'
  config = function() -- This is the function that runs, AFTER loading
    require("which-key").setup {
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 60 }, -- min and max width of the columns
        spacing = 8, -- spacing between columns
        align = "left", -- align columns left, center or right
      },
    }
    -- 注册map，添加说明等等
    require("which-key").register {
      ["<leader>b"] = { name = "[B]uffer", _ = "which_key_ignore" },
      ["<leader>c"] = { name = "[C] gitsigns", _ = "which_key_ignore" },
      ["<leader>d"] = { name = "[D]ebug", _ = "which_key_ignore" },
      ["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
      ["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
      ["<leader>t"] = { t = "ToggleTerm: toggle terminal" },
    }
  end,
}
