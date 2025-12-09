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

---@class LastChange
---@field buf number
---@field filename string
---@field line number
---@field col number

---@type LastChange | nil
local last_change = nil

-- mark when modified to achieve the effect of lastchange
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedT", "TextChangedP", "TextChangedI" }, {
  desc = "Record last change position",
  group = augroup "textChange",
  callback = function(event)
    local relative = vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative
    local buftype = vim.bo[event.buf].buftype
    -- exclude floating window and nofile, terminal, prompt
    if relative == "" and not vim.tbl_contains({ "nofile", "terminal", "prompt" }, buftype) then
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line, col = cursor[1], cursor[2]
      -- record
      last_change = { buf = event.buf, line = line, col = col, filename = vim.api.nvim_buf_get_name(event.buf) }
    end
  end,
})

vim.keymap.set("n", "g.", function()
  if not last_change then
    vim.notify("No last change recorded", vim.log.levels.WARN)
    return
  end
  -- check buffer is still valid
  if vim.api.nvim_buf_is_valid(last_change.buf) and vim.api.nvim_buf_is_loaded(last_change.buf) then
    vim.api.nvim_set_current_buf(last_change.buf)
    vim.api.nvim_win_set_cursor(0, { last_change.line, last_change.col })
  else
    -- load file
    if last_change.filename and vim.fn.filereadable(last_change.filename) == 1 then
      vim.cmd.edit(last_change.filename)
      vim.bo.buflisted = true
      vim.api.nvim_win_set_cursor(0, { last_change.line, last_change.col })
    else
      vim.notify("Last change file does not exist", vim.log.levels.WARN)
      last_change = nil -- reset
    end
  end
end, { desc = "Jump to last change position" })

-- cancel auto-add comment leader
vim.api.nvim_create_autocmd("FileType", {
  command = "set formatoptions-=cro",
})

-- save winview
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
  group = augroup "view_control_save",
  pattern = "*",
  callback = function()
    vim.b.winview = vim.fn.winsaveview()
  end,
})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = augroup "view_control_restore",
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

-- Automatically mark the buffer as modified if the file is deleted
vim.api.nvim_create_autocmd("FileChangedShell", {
  group = augroup "file_modified",
  pattern = "*",
  callback = function(event)
    -- check if file exists
    local file_exists = vim.uv.fs_stat(vim.api.nvim_buf_get_name(event.buf))
    if not file_exists then
      -- Mark the buffer as modified to prevent the 'no longer available' error.
      vim.bo[event.buf].modified = true
    end
  end,
})
