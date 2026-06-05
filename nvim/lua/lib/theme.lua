local M = {}

-- 设置 background 变量
if vim.env.TTY_COLOR_MODE and (vim.env.TTY_COLOR_MODE == "dark" or vim.env.TTY_COLOR_MODE == "light") then
  vim.o.background = vim.env.TTY_COLOR_MODE
else
  vim.env.TTY_COLOR_MODE = nil
end

local function setTheme(theme)
  vim.cmd.colorscheme(theme)
  vim.cmd.hi "Comment gui=none"
end

-- 主题处理器：匹配规则 + 应用方式
local handlers = {
  {
    match = function(name)
      return name:find "tokyonight" ~= nil
    end,
    apply = function(name)
      setTheme(name)
    end,
  },
  {
    match = function(name)
      return name:find "rose" ~= nil
    end,
    apply = function(name)
      setTheme(name)
    end,
  },
  {
    match = function(name)
      return name:find "onedark" ~= nil
    end,
    apply = function(name)
      require("onedark").setup { style = name:match "onedark%-(.+)" or "dark" }
      require("onedark").load()
    end,
  },
  {
    match = function(name)
      return name:find "catppuccin" ~= nil
    end,
    apply = function(name)
      setTheme(name)
    end,
  },
  {
    match = function(name)
      return name:find "nightfox" ~= nil
    end,
    apply = function(name)
      setTheme(name)
    end,
  },
  {
    match = function(name)
      return name:find "github" ~= nil
    end,
    apply = function(name)
      setTheme(name)
    end,
  },
}

-- 计算当前应该使用的主题名
function M.get_theme_name()
  if vim.env.MY_THEME then
    return vim.env.MY_THEME
  end
  return vim.o.background == "light" and "rose-pine-dawn" or "tokyonight"
end

-- 应用主题（供外部调用）
local applying = false
function M.apply_theme()
  if applying then
    return
  end
  applying = true

  local theme = M.get_theme_name()

  for _, h in ipairs(handlers) do
    if h.match(theme) then
      h.apply(theme)
      -- force reload colorscheme
      vim.cmd.doautocmd "ColorScheme"
      break
    end
  end

  applying = false
end

-- 监听 background 变化，自动切换（仅当没有显式设置 MY_THEME 时）
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  callback = function()
    if not vim.env.MY_THEME and not vim.env.TTY_COLOR_MODE then
      M.apply_theme()
    end
  end,
})

-- 插件定义（供 lazy.nvim 使用）
M.plugins = {
  { "folke/tokyonight.nvim", lazy = false },
  { "rose-pine/neovim", lazy = false },
  { "navarasu/onedark.nvim", lazy = false },
  { "catppuccin/nvim", name = "catppuccin", opts = {
    integrations = { blink_cmp = true },
  }, lazy = false },
  { "EdenEast/nightfox.nvim", lazy = false },
  { "projekt0n/github-nvim-theme", name = "github-theme", lazy = false },
}

return M
