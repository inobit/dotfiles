local function augroup(name)
  return vim.api.nvim_create_augroup("inobit_" .. name, { clear = true })
end

-- highlight when copying(:help vim.highlight.on_yank())
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = augroup "highlight_yank",
  callback = function()
    vim.hl.on_yank()
  end,
})

-- mark when modified to achieve the effect of lastchange
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedT", "TextChangedP", "TextChangedI" }, {
  desc = "last change",
  group = augroup "textChange",
  callback = function(event)
    -- need to exclude floating windows
    local relative = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative
    -- exclude NvimTree(nofile) terminal prompt
    local buftype = vim.bo[event.buf].buftype
    if relative == "" and not vim.tbl_contains({ "nofile", "terminal", "prompt" }, buftype) then
      local x, y = unpack(vim.api.nvim_win_get_cursor(0))
      -- Upper case names are required across buffers.
      vim.api.nvim_buf_set_mark(0, "Z", x, y, {})
    end
  end,
})

-- cancel auto-add comment leader
vim.api.nvim_create_autocmd("FileType", {
  command = "set formatoptions-=cro",
})

-- save winview
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  group = augroup "view_control",
  pattern = "*",
  callback = function()
    vim.b.winview = vim.fn.winsaveview()
  end,
})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = augroup "view_control",
  pattern = "*",
  callback = function()
    if vim.b.winview ~= nil then
      vim.fn.winrestview(vim.b.winview)
    end
  end,
})

-- hidden levels of json files
vim.api.nvim_create_autocmd("FileType", {
  group = augroup "json_conceal",
  pattern = { "json", "json5", "jsonc" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- auto load run module
vim.api.nvim_create_autocmd("FileType", {
  group = augroup "run",
  pattern = { "python", "c", "cpp", "javascript" },
  callback = function()
    require "lib.run"
  end,
})

-- strong,italic highlight
vim.api.nvim_create_autocmd("FileType", {
  group = augroup "md_highlight",
  pattern = "markdown",
  callback = function()
    vim.api.nvim_set_hl(0, "@markup.strong", { fg = "#ff6347", bg = "", bold = true })
    vim.api.nvim_set_hl(0, "@markup.italic", { fg = "#4acfd3", bg = "", italic = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup "close_with_q",
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd "close"
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist(very useful for java development)
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup "auto_create_dir",
  callback = function(event)
    if event.match:match "^%w%w+:[\\/][\\/]" then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup "checktime",
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd "checktime"
    end
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup "resize_splits",
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd "tabdo wincmd ="
    vim.cmd("tabnext " .. current_tab)
  end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd("FileType", {
  group = augroup "man_unlisted",
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})
