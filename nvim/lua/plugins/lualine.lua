return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
  },
  init = function()
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  config = function()
    local function get_formatter()
      local status, conform = pcall(require, "conform")
      if status then
        local formatter = conform.list_formatters(0)
        if not vim.tbl_isempty(formatter) then
          return formatter[1].name
        end
      end
      return "None"
    end
    require("lualine").setup {
      icons_enabled = true,
      sections = {
        lualine_b = {
          "branch",
          "diff",
          "diagnostics",
        },
        lualine_c = {
          { "filename", path = 1 },
          -- { require("auto-session.lib").current_session_name },
        },
        lualine_x = {
          -- stylua: ignore start
          {
            function() return "  " .. require("dap").status() end,
            cond = function()
              local status, dap = pcall(require, "dap")
              return status and dap.status() ~= ""
            end,
            color = "Debug",
          },
          {
            function()
              -- return "󰦕" .. table.concat(require("lint").get_running(), ", ")
              return "󰦕 " .. table.concat(vim.g.lint_names, ", ")
            end,
            cond = function() return vim.g.lint_names and #vim.g.lint_names > 0 end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Statement", link = false }).fg) }
            end,
          },
          {
            get_formatter,
            icon = {
              "󰉠",
              color = function()
                return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg) }
              end,
            },
          },
          "encoding",
          "fileformat",
          "filetype",
        },
        -- stylua: ignore end
      },
      extensions = { "quickfix", "nvim-tree", "toggleterm", "nvim-dap-ui", "mason", "lazy" },
    }
  end,
}
