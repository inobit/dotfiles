require "lib.lazy"
--[[ {
-- 自定义插件例子，本地加载
  dir = '~/myplugin.nvim',
-- init优先load执行，load执行后触发config函数，init是load的pre hook,config是post hook
  init = function() print('myplugin init') end,
  config = true,
  -- keys = "j"
}, ]]
-- import plugins 会自动导入lua/plugins/*.lua文件
require("lazy").setup {
  spec = { { import = "plugins" } },
  ui = {
    -- If you have a Nerd Font, set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
  dev = { path = vim.fn.expand(vim.env.LOCAL_PLUGINS_DIR or "~/projects") },
  change_detection = {
    enabled = false,
    notify = false,
  },
}
