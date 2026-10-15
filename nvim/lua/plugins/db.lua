return {
  {
    "2giosangmitom/sqmeow.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    -- 自动下载预编译的 Rust engine（Linux/macOS/Windows 均有，失败才回退 cargo）
    build = function()
      require("sqmeow").install()
    end,
    keys = {
      {
        "<leader>Q",
        function()
          require("sqmeow.api.view").toggle()
        end,
        desc = "Sqmeow: toggle",
      },
    },
    opts = {
      keymaps = {
        -- 沿用全局 run 约定：<leader>rr>（与 nvim-java、lib/run 一致）
        editor = {
          execute_statement = "<leader>rr", -- normal：运行光标下语句
          execute_selection = "<leader>rr", -- visual：运行选中
        },
        drawer = {
          refresh = "R",
          rename = "r",
        },
        result = {
          next_page = ">",
          prev_page = "<",
          first_page = "<leader><",
          last_page = "<leader>>",
          export = "e",
          export_selection = "e",
        },
      },
    },
    config = function(_, opts)
      require("sqmeow").setup(opts)

      -- sqmeow 原生的 editor 键位只映射在自己的 scratchpad 里；
      -- 这里让任意 .sql/.mysql/.plsql 文件也能用同样的键运行查询
      local pattern = { "sql", "mysql", "plsql" }
      local function attach(ev)
        local buf = type(ev) == "number" and ev or ev.buf
        if not vim.tbl_contains(pattern, vim.bo[buf].filetype) then
          return
        end
        local keymap = require "sqmeow.keymap"
        local query = require "sqmeow.api.query"
        local lhs = keymap.lhs("editor", "execute_statement")
        if lhs then
          vim.keymap.set("n", lhs, function()
            query.execute_statement()
          end, { buffer = buf, desc = "Sqmeow: run statement" })
        end
        local lhs_v = keymap.lhs("editor", "execute_selection")
        if lhs_v then
          vim.keymap.set("x", lhs_v, function()
            query.execute_selection()
          end, { buffer = buf, desc = "Sqmeow: run selection" })
        end
      end
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("sqmeow_editor_keys", { clear = true }),
        pattern = pattern,
        callback = attach,
      })
      -- 启动时已加载的 sql buffer（FileType 早于 config 触发）
      vim.tbl_map(attach, vim.api.nvim_list_bufs())
    end,
  },
}
