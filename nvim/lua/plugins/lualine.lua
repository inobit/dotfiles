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
            function() return "󰅾 " .. require("inobit.llm.api"):has_active_chats() .. "/" .. require("inobit.llm.api"):has_chats() end,
            cond = function() return package.loaded["inobit.llm"] and require("inobit.llm.api"):has_chats() > 0 end,
            color = function() return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "DiagnosticHint", link = false }).fg) } end,
          },
          {
            function() return "󰗊 "..  require("inobit.llm.api").is_translating() end,
            cond = function() return package.loaded["inobit.llm"] and require("inobit.llm.api").is_translating() ~= nil end,
            color = function() return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "DiagnosticHint", link = false }).fg) } end,
          },
          {
            function()
              local lsps = vim
                .iter(vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() })
                :map(function(client)
                  return client.name
                end)
                :totable()
              return "  " .. table.concat(lsps, ", ")
            end,
            cond = function() return #vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() } > 0 end,
            color = function() return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Define", link = false }).fg) } end,
          },
          {
            function() return "  " .. require("dap").status() end,
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Debug", link = false }).fg) }
            end,
          },
          {
            function()
              return " " .. table.concat(vim.b.lint_names, ", ")
            end,
            cond = function() return vim.b.lint_names and #vim.b.lint_names > 0 end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Character", link = false }).fg) }
            end,
          },
          {
            function()
              local status = table.concat(vim.b.linters, ", ")
              return " " .. status
            end,
            cond = function() return vim.b.linters and #vim.b.linters > 0 end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "Character", link = false }).fg) }
            end,
          },
          {
            function()
              local status = table.concat(vim.b.formatters, ", ")
              return "󰉠 " .. status
            end,
            cond = function() return vim.b.formatters and #vim.b.formatters > 0 end,
            color = function()
              return { fg = string.format("#%06x", vim.api.nvim_get_hl(0, { name = "WarningMsg", link = false }).fg) }
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
