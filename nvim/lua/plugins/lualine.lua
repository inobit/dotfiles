return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
  },
  init = function()
    vim.g.lualine_laststatus = vim.o.laststatus
    if vim.fn.argc(-1) > 0 then
      -- set an empty statusline till lualine loads
      vim.o.statusline = " "
    else
      -- hide the statusline on the starter page
      vim.o.laststatus = 0
    end
  end,
  config = function()
    vim.o.laststatus = vim.g.lualine_laststatus
    require("lualine").setup {
      icons_enabled = true,
      options = {
        theme = "auto",
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
        refresh = {
          statusline = 300,
        },
      },
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
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Debug", link = false }).fg) }
            end,
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
            function()
              local formatters = require("conform").list_formatters()
              local status = "None"
              if #formatters > 0 then
                status = table.concat(vim.iter(require("conform").list_formatters()):map(function(f) return f.name end):totable(), ", ")
              end
              return "󰉠 " .. status
            end,
            cond = function() return package.loaded["conform"] ~= nil end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Special", link = false }).fg) }
            end,
          },
          -- stylua: ignore end
          "encoding",
          "fileformat",
          "filetype",
        },
      },
      extensions = { "quickfix", "nvim-tree", "toggleterm", "nvim-dap-ui", "mason", "lazy" },
    }
  end,
}
