return {
  {
    "kndndrj/nvim-dbee",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    build = function()
      -- Install tries to automatically detect the install method.
      -- if it fails, try calling it with one of these parameters:
      --    "curl", "wget", "bitsadmin", "go"
      if not vim.fn.has "win32" then
        require("dbee").install "curl"
      end
      -- windows manual install
    end,
    keys = {
      {
        "<leader>Dt",
        function()
          if require("dbee").is_open() then
            local bufnr = require("dbee.api").ui.editor_get_current_note().bufnr
            if bufnr then
              if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
                vim.api.nvim_buf_call(bufnr, function()
                  vim.cmd.write()
                end)
              end
              --BUG: null-ls(vim.lsp.buf.format) and supermaven inline mode, will cause the unlisted property of the buffer to become true
              if vim.api.nvim_get_option_value("buflisted", { buf = bufnr }) then
                vim.api.nvim_buf_delete(bufnr, { force = true })
              end
            end
          end

          require("dbee").toggle()
        end,
        desc = "DBee: toggle",
      },
    },
    config = function()
      local api = require "dbee.api"
      local dbee = require "dbee"
      dbee.setup {
        -- sources = {
        --   require("dbee.sources").MemorySource:new {
        --     {
        --       id = "xxx",
        --       name = "xxx",
        --       type = "mysql",
        --       url = "username:password@tcp(host)/database-name",
        --     },
        --   },
        -- },
        drawer = {
          mappings = {
            -- manually refresh drawer
            { key = "R", mode = "n", action = "refresh" },
            -- actions perform different stuff depending on the node:
            -- action_1 opens a note or executes a helper
            { key = "<CR>", mode = "n", action = "action_1" },
            -- action_2 renames a note or sets the connection as active manually
            { key = "r", mode = "n", action = "action_2" },
            -- action_3 deletes a note or connection (removes connection from the file if you configured it like so)
            { key = "dd", mode = "n", action = "action_3" },
            -- these are self-explanatory:
            -- { key = "c", mode = "n", action = "collapse" },
            -- { key = "e", mode = "n", action = "expand" },
            { key = "o", mode = "n", action = "toggle" },
            -- mappings for menu popups:
            { key = "<CR>", mode = "n", action = "menu_confirm" },
            { key = "y", mode = "n", action = "menu_yank" },
            { key = "<Esc>", mode = "n", action = "menu_close" },
            { key = "q", mode = "n", action = "menu_close" },
          },
        },
        result = {
          mappings = {
            { key = ">", mode = "", action = "page_next" },
            { key = "<", mode = "", action = "page_prev" },
            { key = "<leader>>", mode = "", action = "page_last" },
            { key = "<leader><", mode = "", action = "page_first" },
            -- yank rows as csv/json
            { key = "<leader>yj", mode = "n", action = "yank_current_json" },
            { key = "<leader>yj", mode = "v", action = "yank_selection_json" },
            { key = "<leader>yJ", mode = "", action = "yank_all_json" },
            { key = "<leader>yc", mode = "n", action = "yank_current_csv" },
            { key = "<leader>yc", mode = "v", action = "yank_selection_csv" },
            { key = "<leader>yC", mode = "", action = "yank_all_csv" },
          },
        },
        editor = {
          mappings = {
            -- run what's currently selected on the active connection
            { key = "<leader>rr", mode = "v", action = "run_selection" },
            -- run the whole file on the active connection
            -- { key = "", mode = "n", action = "run_file" },
            -- run what's under the cursor to the next newline
            { key = "<leader>rr", mode = "n", action = "run_under_cursor" },
          },
        },
      }

      -- export result to csv
      vim.api.nvim_create_user_command("DbeeExport", function()
        if dbee.is_open() then
          if api.ui.result_get_call() then
            local note = api.ui.editor_get_current_note().name
            if note:match ".*%.sql$" then
              note = note:gsub("%.sql$", "")
            end
            vim.ui.input({
              prompt = "Export to: ",
              default = "~/downloads/" .. note .. ".csv",
            }, function(input)
              if input then
                vim.cmd("Dbee store csv file " .. vim.fn.expand(input))
                vim.notify "Export completion!"
              end
            end)
          else
            vim.notify "No Dbee call is selected!"
          end
        else
          vim.notify "No DBee opened!"
        end
      end, { desc = "Dbee: export" })

      -- show current connection in winbar
      local show_current_connection = require("lib.dbee").show_current_connection
      api.core.register_event_listener("current_connection_changed", function()
        -- show_current_connection()
      end)
      api.ui.editor_register_event_listener("current_note_changed", function()
        -- show_current_connection()
      end)
    end,
  },
  {
    "MattiasMTS/cmp-dbee",
    -- cond = false,
    dependencies = {
      { "kndndrj/nvim-dbee" },
    },
    ft = "sql", -- optional but good to have
    opts = {}, -- needed
  },
}
