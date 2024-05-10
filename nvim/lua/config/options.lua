vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

-- :h hidden 允许隐藏buffer(toggleterm plugin)
vim.opt.hidden = true

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
-- 不需要显示模式，比如 --INSERT--
vim.opt.showmode = false
-- 系统剪切板，ssh远程的需要配置x-client和x-server
vim.opt.clipboard = "unnamedplus"

-- 换行后重复之前的缩进
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- 写入swap等待时间，避免没有及时保存
vim.opt.updatetime = 250
-- 设置按键间隔
vim.opt.timeoutlen = 300

-- 垂直分割在右边，水平分割在下面
vim.opt.splitright = true
vim.opt.splitbelow = true

-- 空白的不可见字符是否显示
vim.opt.list = true
-- 使用哪种符号来显示
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- 提前预览命令的修改效果，目前支持:s
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- tab使用空格
vim.opt.expandtab = true
-- 缩进2字符
vim.opt.shiftwidth = 2
-- 制表符的显示长度
vim.opt.tabstop = 2
-- 插入模式下tab插入的长度，如果和tabstop不同，则会使用制表符和空格混合来达成效果
-- 比如sts=5 ts=2，insert时一次tab会显示为2个制表符和1个空格
vim.opt.softtabstop = 2
