return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = { "<leader>tt" },
  cmd = { "ToggleTerm" },
  init = function()
    -- windows 支持
    if vim.fn.has "win32" == 1 then
      local powershell_options = {
        shell = vim.fn.executable "pwsh" == 1 and "pwsh" or "powershell",
        shellcmdflag = "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;",
        shellredir = "-RedirectStandardOutput %s -NoNewWindow -Wait",
        shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode",
        shellquote = "",
        shellxquote = "",
      }
      for option, value in pairs(powershell_options) do
        vim.opt[option] = value
      end
    end
    -- :q退出,会丢失ToggleTerm的追踪效果，导致再次使用ToggleTerm时自动切换到第一个了
    vim.api.nvim_create_autocmd("TermEnter", {
      pattern = [[term://*toggleterm#*]],
      callback = function()
        vim.keymap.set(
          "n",
          "<leader>q",
          "<Cmd>ToggleTerm<CR>",
          { buffer = 0, noremap = true, silent = true, desc = "ToggleTerm: 使用ToggleTerm来退出" }
        )
      end,
    })
  end,
  config = function()
    local toggleterm = require "toggleterm"
    toggleterm.setup {
      size = function(term)
        if term.direction == "horizontal" then
          return 10
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.2
        end
      end,
      open_mapping = "<leader>tt",
      trim_spaces = false,
      -- 不要开启否则影响插入模式下的输入,特别是使用了space作为leader,会造成空格卡顿
      insert_mappings = false,
      terminal_mappings = false,
      persist_size = true,
      persist_mode = true,
      direction = "horizontal", -- 'vertical' | 'horizontal' | 'tab' | 'float'
      shell = vim.o.shell,
    }
    -- key mappings
    local map = function(mode, lhs, rhs, opts)
      vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", { noremap = true, silent = true }, opts))
    end
    -- 切换terminal方向,默认vertical
    map("n", "<leader>vh", function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        if vim.bo[bufnr].buftype == "terminal" then
          local _, term = require("toggleterm.terminal").identify(vim.api.nvim_buf_get_name(bufnr))
          if term and term:is_split() then
            return "<Cmd>ToggleTerm<CR><Cmd>ToggleTerm direction="
              .. (term.direction == "horizontal" and "vertical" or "horizontal")
              .. "<CR>"
          end
        end
      end
      return "<Cmd>ToggleTerm direction=vertical<CR>"
    end, { expr = true, desc = "ToggleTerm: 切换terminal方向" })
    map("n", "<leader>st", "<Cmd>TermSelect<CR>", { desc = "ToggleTerm: terminal select" })
    -- open_mapping <leader>te可达到效果
    --[[ map("n", "<leader>tt", function()
      vim.cmd(vim.v.count .. "ToggleTerm")
    end, { desc = "ToggleTerm: toggle terminal" }) ]]
    map("n", "<leader>ta", "<Cmd>ToggleTermToggleAll<CR>", { desc = "ToggleTerm: toggle all terminal" })
  end,
}
