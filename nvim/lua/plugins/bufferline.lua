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
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- nvim-tree和bufferline配合有bug,使用bd删除当前buffer时,会造成nvim-tree认为没有buffer了,会resize来占满整个屏幕.引入bufremove来解决
    { "echasnovski/mini.bufremove", version = "*" },
  },
  config = function()
    local bufferline = require "bufferline"
    bufferline.setup {
      options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead style_preset = bufferline.style_preset.no_italic, -- or bufferline.style_preset.minimal,
        themable = false, -- allows highlight goups to be overriden i.e. sets highlights as default
        numbers = "none",
        close_command = function(n)
          require("mini.bufremove").delete(n, false)
        end,
        right_mouse_command = function(n)
          require("mini.bufremove").delete(n, false)
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
        -- The diagnostics indicator can be set to nil to keep the buffer name highlight but delete the highlighting
        diagnostics_indicator = function()
          return ""
        end,
        --[[ custom_filter = function(buf_number)
          print("filetype", vim.inspect(vim.bo[buf_number]))
          if vim.bo[buf_number].buftype == "terminal" then
            return false
          else
            return true
          end
        end, ]]
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
        always_show_bufferline = true,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",

        groups = {
          items = {
            require("bufferline.groups").builtin.pinned:with { icon = "" },
          },
        },
      },
    }
    -- key mappings
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = "BufferLine: " .. desc, noremap = true, silent = true })
    end
    -- map("<leader>l", "<Cmd>BufferLineCycleNext<CR>", "Go to the [N]ext buffer in buffer list.")
    -- map("<leader>h", "<Cmd>BufferLineCyclePrev<CR>", "Go to the [P]revious buffer in buffer list.")
    map("<leader>l", function()
      if vim.v.count == 0 then
        vim.cmd "BufferLineCycleNext"
      else
        bufferline.go_to(getRelativeIndex(vim.v.count), false)
      end
    end, "跳到相对当前右边第v:count个buffer")
    map("<leader>h", function()
      if vim.v.count == 0 then
        vim.cmd "BufferLineCyclePrev"
      else
        bufferline.go_to(getRelativeIndex(-vim.v.count), false)
      end
    end, "跳到相对当前左边第v:count个buffer")
    -- map("<leader>L", "<Cmd>BufferLineMoveNext<CR>", "move [N]ext")
    -- map("<leader>H", "<Cmd>BufferLineMovePrev<CR>", "move [P]revious")
    map("<leader>L", function()
      if vim.v.count == 0 then
        vim.cmd "BufferLineMoveNext"
      else
        bufferline.move_to(getRelativeIndex(vim.v.count))
      end
    end, "移动到相对当前右边第v:count个buffer")
    map("<leader>H", function()
      if vim.v.count == 0 then
        vim.cmd "BufferLineMovePrev"
      else
        bufferline.move_to(getRelativeIndex(-vim.v.count))
      end
    end, "移动到相对当前右边第v:count个buffer")

    map("<leader>bb", function()
      require("mini.bufremove").delete(0, false)
    end, "[C]lose current buffer")
    map("<leader>bf", function()
      require("mini.bufremove").delete(0, true)
    end, "[F]orce [C]lose current buffer")
    map("<leader>bh", "<Cmd>BufferLineCloseLeft<CR>", "close all visible buffers to the [L]eft of the")
    map("<leader>bl", "<Cmd>BufferLineCloseRight<CR>", "close all visible buffers to the [R]ight of the current")
    map("<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", "close all [O]ther visible buffers")
    map("<leader>bp", "<Cmd>BufferLineTogglePin<CR>", "buffer line [P]in toggle")
    map("<leader>bs", "<Cmd>BufferLinePick<CR>", "buffer line [P]ick")
    map("<leader>bS", "<Cmd>BufferLinePickClose<CR>", "buffer line [P]ick to close")
  end,
  --[[ vim.api.nvim_create_autocmd("BufAdd", {
    callback = function()
      vim.schedule(function()
        pcall(nvim_bufferline)
      end)
    end,
  }), ]]
}
