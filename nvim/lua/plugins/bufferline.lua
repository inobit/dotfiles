local getRelativeIndex = function(count)
  local commands = require "bufferline.commands"
  local bufferstate = require "bufferline.state"
  local index = commands.get_current_element_index(bufferstate)
  local toIndex = index + count
  if toIndex > #bufferstate.components then
    return #bufferstate.components
  elseif toIndex < 1 then
    return 1
  else
    return toIndex
  end
end

return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  keys = {
    {
      "<leader>l",
      function()
        if vim.v.count == 0 then
          vim.cmd "BufferLineCycleNext"
        else
          require("bufferline").go_to(getRelativeIndex(vim.v.count), false)
        end
      end,
      desc = "Bufferline: [v:count] Next buffer",
    },
    {
      "<leader>h",
      function()
        if vim.v.count == 0 then
          vim.cmd "BufferLineCyclePrev"
        else
          require("bufferline").go_to(getRelativeIndex(-vim.v.count), false)
        end
      end,
      desc = "Bufferline: [v:count] Prev buffer",
    },
    {
      "<leader>L",
      function()
        if vim.v.count == 0 then
          vim.cmd "BufferLineMoveNext"
        else
          require("bufferline").move_to(getRelativeIndex(vim.v.count))
        end
      end,
      desc = "Bufferline: [v:count] Move buffer next",
    },
    {
      "<leader>H",
      function()
        if vim.v.count == 0 then
          vim.cmd "BufferLineMovePrev"
        else
          require("bufferline").move_to(getRelativeIndex(-vim.v.count))
        end
      end,
      desc = "Bufferline: [v:count] Move buffer prev",
    },

    {
      "<leader>bb",
      function()
        Snacks.bufdelete { force = false }
      end,
      desc = "Bufferline: Close current buffer",
    },
    {
      "<leader>bf",
      function()
        Snacks.bufdelete { force = true }
      end,
      desc = "Bufferline: Force Close current buffer",
    },
    {
      "<leader>bh",
      "<Cmd>BufferLineCloseLeft<CR>",
      desc = "Bufferline: Close all visible buffers to the Left of the",
    },
    {
      "<leader>bl",
      "<Cmd>BufferLineCloseRight<CR>",
      desc = "Bufferline: Close all visible buffers to the Right of the current",
    },
    {
      "<leader>bo",
      "<Cmd>BufferLineCloseOthers<CR>",
      desc = "Bufferline: Close all Other visible buffers",
    },
    {
      "<leader>bp",
      "<Cmd>BufferLineTogglePin<CR>",
      desc = "Bufferline: Pin toggle",
    },
    { "<leader>bs", "<Cmd>BufferLinePick<CR>", desc = "Bufferline: Pick" },
    {
      "<leader>bS",
      "<Cmd>BufferLinePickClose<CR>",
      desc = "Bufferline: Pick to close",
    },
  },
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    options = {
      mode = "buffers", -- set to "tabs" to only show tabpages instead style_preset = bufferline.style_preset.no_italic, -- or bufferline.style_preset.minimal,
      themable = false, -- allows highlight goups to be overriden i.e. sets highlights as default
      numbers = "none",
      close_command = function(n)
        Snacks.bufdelete(n)
      end,
      right_mouse_command = function(n)
        Snacks.bufdelete(n)
      end,
      --[[ close_command = "bdelete! %d", -- can be a string | function, | false see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        left_mouse_command = "buffer %d", -- can be a string | function, | false see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, | false see "Mouse actions" ]]
      indicator = {
        icon = "▎", -- this should be omitted if indicator style is not 'icon'
        style = "icon",
      },
      buffer_close_icon = "󰅖",
      modified_icon = "●",
      close_icon = "",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 18,
      max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
      truncate_names = true, -- whether or not tab names should be truncated
      tab_size = 18,
      diagnostics = "nvim_lsp",
      diagnostics_update_in_insert = false,
      diagnostics_indicator = "nvim_lsp",
      offsets = {
        {
          filetype = "NvimTree",
          text = "File Explorer",
          highlight = "Directory",
          text_align = "left",
          separator = true,
        },
      },
      color_icons = true, -- whether or not to add the filetype icon highlights
      show_buffer_icons = true, -- disable filetype icons for buffers
      show_buffer_close_icons = false,
      show_close_icon = true,
      show_tab_indicators = true,
      show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
      duplicates_across_groups = true, -- whether to consider duplicate paths in different groups as duplicates
      persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
      move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
      -- can also be a table containing 2 custom separators
      -- [focused and unfocused]. eg: { '|', '|' }
      separator_style = "slant",
      enforce_regular_tabs = true,
      always_show_bufferline = false, -- when there is only one buffer, it will not be displayed.
      hover = {
        enabled = true,
        delay = 200,
        reveal = { "close" },
      },
      sort_by = "insert_after_current",
    },
  },
}
