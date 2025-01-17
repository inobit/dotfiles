return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    vim.keymap.set(
      "n",
      "<leader>fe",
      "<cmd>NvimTreeFocus<CR>",
      { noremap = true, silent = true, desc = "NvimTree: focus explore" }
    )
    vim.keymap.set(
      "n",
      "<leader>te",
      "<cmd>NvimTreeToggle<CR>",
      { noremap = true, silent = true, desc = "NvimTree: toggle explore" }
    )
    require("nvim-tree").setup {
      update_focused_file = {
        enable = true,
        -- update_root = true,
        ignore_list = {},
      },
      disable_netrw = true,
      hijack_netrw = true,
      on_attach = function(bufnr)
        local api = require "nvim-tree.api"
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        -- default mappings
        api.config.mappings.default_on_attach(bufnr)
        -- custom mappings
        vim.keymap.set("n", "<leader>v", api.node.open.vertical, opts "Open: vertical Split")
        vim.keymap.set("n", "<leader>s", api.node.open.horizontal, opts "Open: horizontal Split")
        vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts "Next Diagnostic")
        vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts "Prev Diagnostic")
        vim.keymap.set("n", "<leader>cd", api.tree.change_root_to_node, opts "CD")
        vim.keymap.set("n", "<leader>cp", api.tree.change_root_to_parent, opts "Up")

        -- disable highlight group NvimTreeSpecialFile underline
        local color = vim.api.nvim_get_hl(0, {
          name = "NvimTreeSpecialFile",
        })
        if color then
          color.underline = nil
          if color.cterm and color.cterm.underline then
            color.cterm.underline = nil
          end
          vim.api.nvim_set_hl(0, "NvimTreeSpecialFile", color --[[@as vim.api.keyset.highlight]])
        end
      end,
      view = {
        signcolumn = "yes",
        side = "left",
      },
      renderer = {
        root_folder_label = ":t",
        icons = {
          git_placement = "before",
          diagnostics_placement = "signcolumn",
          modified_placement = "after",
          bookmarks_placement = "signcolumn",
          glyphs = {
            default = "",
            symlink = "",
            modified = "●",
            folder = {
              arrow_closed = "",
              arrow_open = "",
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
            },
            git = {
              unstaged = "",
              staged = "✓",
              unmerged = "",
              renamed = "➜",
              untracked = "U",
              deleted = "",
              ignored = "◌",
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        severity = {
          min = vim.diagnostic.severity.HINT,
          max = vim.diagnostic.severity.ERROR,
        },
        icons = {
          hint = "",
          info = "",
          warning = "",
          error = "",
        },
      },
      actions = {
        open_file = {
          resize_window = true,
          -- 关闭pick window否则split/vsplit open会失败
          window_picker = {
            enable = true,
          },
        },
        change_dir = {
          enable = true,
          -- change_dir时影响全局,使用cd 代替 lcd
          global = true,
          restrict_above_cwd = false,
        },
      },
    }
  end,
}
