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
    local function get_linters()
      local status, lint = pcall(require, "lint")
      if status then
        local linters = lint.get_running()
        if #linters == 0 then
          return "󰦕"
        end
        return "󱉶 " .. table.concat(linters, ", ")
      end
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
          get_linters,
          { get_formatter, icon = { "󰉠" } },
          "encoding",
          "fileformat",
          "filetype",
        },
      },
      extensions = { "quickfix", "nvim-tree", "toggleterm", "nvim-dap-ui", "mason", "lazy" },
    }
  end,
}
