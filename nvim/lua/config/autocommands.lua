-- 复制的时候，高亮显示
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
-- 修改时mark，达到lastchange的效果
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedT", "TextChangedP", "TextChangedI" }, {
  desc = "last change",
  group = vim.api.nvim_create_augroup("textChange", { clear = true }),
  callback = function(event)
    -- 需要排除浮动窗口
    local relative = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative
    -- 排除NvimTree(nofile) terminal prompt
    local buftype = vim.bo[event.buf].buftype
    if relative == "" and not vim.tbl_contains({ "nofile", "terminal", "prompt" }, buftype) then
      local x, y = unpack(vim.api.nvim_win_get_cursor(0))
      -- 跨buffer需要使用大写name
      vim.api.nvim_buf_set_mark(0, "Z", x, y, {})
    end
  end,
})
-- 如果最后一个buffer是NvimTree则直接退出
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NvimTreeClose", { clear = true }),
  pattern = "NvimTree_*",
  callback = function()
    local layout = vim.api.nvim_call_function("winlayout", {})
    if
      layout[1] == "leaf"
      and layout[3] == nil
      and vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_win_get_buf(layout[2]) }) == "NvimTree"
    then
      -- 提示保存
      vim.cmd "confirm quit"
    end
  end,
})
-- 自动着色
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("Colorizer", {
    clear = true,
  }),
  pattern = {
    "*.html",
    "*.css",
    "*.scss",
    "*.less",
    "*.sass",
    "*.ts",
    "*.js",
    "*.tsx",
    "*.jsx",
  },
  callback = function()
    local status, colorizer = pcall(require, "colorizer")
    if status then
      colorizer.attach_to_buffer(0)
    end
  end,
})

-- 取消自动添加comment leader
vim.api.nvim_create_autocmd("FileType", {
  command = "set formatoptions-=cro",
})

-- save winview
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  group = vim.api.nvim_create_augroup("view_control", { clear = false }),
  pattern = "*",
  callback = function()
    vim.b.winview = vim.fn.winsaveview()
  end,
})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("view_control", { clear = false }),
  pattern = "*",
  callback = function()
    if vim.b.winview ~= nil then
      vim.fn.winrestview(vim.b.winview)
    end
  end,
})

-- json文件的隐藏级别
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("json_conceal", { clear = true }),
  pattern = { "json", "json5", "jsonc", "markdown" },
  callback = function()
    vim.opt.conceallevel = 0
  end,
})

-- auto load run module
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("run", { clear = true }),
  pattern = { "python", "c", "cpp", "javascript" },
  callback = function()
    require "dap_set.run"
  end,
})

-- strong,italic highlight
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("md_highlight", { clear = true }),
  pattern = "markdown",
  callback = function()
    vim.api.nvim_set_hl(0, "@markup.strong", { fg = "#ff6347", bg = "", bold = true })
    vim.api.nvim_set_hl(0, "@markup.italic", { fg = "#4acfd3", bg = "", italic = true })
  end,
})
