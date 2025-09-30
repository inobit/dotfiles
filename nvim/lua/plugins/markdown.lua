return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    -- ft = "markdown",
    event = {
      "BufReadPre " .. vim.g.obsidian_vault .. "*.md",
      "BufNewFile " .. vim.g.obsidian_vault .. "*.md",
      "BUfWritePre " .. vim.g.obsidian_vault .. "*.md",
    },
    init = function()
      -- create work and personal dir
      if vim.fn.isdirectory(vim.g.obsidian_vault .. "personal/") == 0 then
        vim.fn.mkdir(vim.g.obsidian_vault .. "personal/", "p")
      end
      if vim.fn.isdirectory(vim.g.obsidian_vault .. "work/") == 0 then
        vim.fn.mkdir(vim.g.obsidian_vault .. "work/", "p")
      end
    end,
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      workspaces = {
        {
          name = "personal",
          path = vim.fn.expand(vim.g.obsidian_vault .. "personal/"),
        },
        {
          name = "work",
          path = vim.fn.expand(vim.g.obsidian_vault .. "work/"),
        },
      },
      legacy_commands = false,
      callbacks = {
        enter_note = function(_, note)
          -- stylua: ignore start
          vim.keymap.set("n", "]s", function() require("obsidian.api").nav_link "next" end, { buffer = note.bufnr, desc = "Obsidian: Go to next link", })
          vim.keymap.set("n", "[s", function() require("obsidian.api").nav_link "prev" end, { buffer = note.bufnr, desc = "Obsidian: Go to previous link", })
          -- override telescope keymaps
          vim.keymap.set("n", "<leader>sf", "<CMD>Obsidian quick_switch<CR>", { buffer = note.bufnr, desc = "Obsidian: search" })
          vim.keymap.set("n", "<leader>sg", "<CMD>Obsidian search<CR>", { buffer = note.bufnr, desc = "Obsidian: grep" })
          -- stylua: ignore end
        end,
      },
    },
  },
  {
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
      quote = {
        repeat_linebreak = true,
      },
      win_options = {
        showbreak = {
          default = vim.opt.showbreak,
          rendered = "  ",
        },
      },
    },
    ft = { "markdown", "norg", "rmd", "org", vim.g.inobit_filetype, "Avante" },
  },
}
