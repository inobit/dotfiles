return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<M-h>"] = "actions.select_split",
        ["q"] = { "actions.close", mode = "n" },
        ["<leader>R"] = { "actions.refresh", mode = "n" },
      },
      view_options = {
        show_hidden = true,
      },
    },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function(_, opts)
      CustomOilBar = function()
        local path = vim.fn.expand "%"
        path = path:gsub("oil://", "")
        return "  " .. vim.fn.fnamemodify(path, ":.")
      end
      opts.win_options = {
        winbar = "%{v:lua.CustomOilBar()}",
        -- for oil-git-status.nvim
        signcolumn = "yes:2",
        statuscolumn = "", -- conflic with snack.statuscolumn, so just use default value
      }
      require("oil").setup(opts)
      vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
      -- Open parent directory in floating window
      vim.keymap.set("n", "<leader>-", require("oil").toggle_float)
    end,
  },
  {
    "refractalize/oil-git-status.nvim",
    dependencies = {
      "stevearc/oil.nvim",
    },
    opts = {
      show_ignored = true,
      symbols = { -- customize the symbols that appear in the git status columns
        index = {
          ["!"] = "◌",
          ["?"] = "U",
          ["A"] = "✓",
          ["C"] = "❐",
          ["D"] = "",
          ["M"] = "",
          ["R"] = "➜",
          ["T"] = "⇄",
          ["U"] = "",
          [" "] = " ",
        },
        working_tree = {
          ["!"] = "◌",
          ["?"] = "U",
          ["A"] = "✓",
          ["C"] = "❐",
          ["D"] = "",
          ["M"] = "",
          ["R"] = "➜",
          ["T"] = "⇄",
          ["U"] = "",
          [" "] = " ",
        },
      },
    },
    config = function(_, opts)
      require("oil-git-status").setup(opts)

      ---@param direction "prev" | "next"
      ---@param signs vim.api.keyset.get_extmark_item[]
      ---@return number | nil
      local function get_next_sign(direction, signs)
        local next_line = nil
        if not signs or #signs == 0 then
          return nil
        end
        local line = vim.fn.line "."
        for _, sign in ipairs(signs) do
          if direction == "prev" then
            if sign[2] + 1 >= line then
              return next_line
            end
          end
          if
            sign[4].sign_hl_group ~= "OilGitStatusIndexUnmodified"
            and sign[4].sign_hl_group ~= "OilGitStatusWorkingTreeUnmodified"
          then
            next_line = sign[2] + 1
          end
          if direction == "next" then
            if next_line and next_line > line then
              return next_line
            end
          end
        end
      end

      local plugin_namespace = "oil-git-status"

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("inobit_oil_next_change", { clear = true }),
        pattern = { "oil" },
        callback = function(context)
          local bufnr = context.buf
          local git_signs = { signs = {} }
          vim.keymap.set("n", "]c", function()
            local next_line = get_next_sign("next", git_signs.signs)
            if next_line then
              vim.api.nvim_win_set_cursor(0, { next_line, 0 })
            end
          end, { buffer = bufnr, desc = "Oil: Go to next change" })
          vim.keymap.set("n", "[c", function()
            local next_line = get_next_sign("prev", git_signs.signs)
            if next_line then
              vim.api.nvim_win_set_cursor(0, { next_line, 0 })
            end
          end, { buffer = bufnr, desc = "Oil: Go to prev change" })

          vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
            buffer = bufnr,
            group = vim.api.nvim_create_augroup("inobit_oil_refresh_signs", { clear = true }),
            callback = function()
              local namespace = vim.api.nvim_get_namespaces()[plugin_namespace]
              git_signs.signs =
                vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { hl_name = true, details = true })
            end,
          })
        end,
      })
    end,
  },
}
