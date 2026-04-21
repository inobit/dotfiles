if not vim.g.vscode then
  require "config.env"
  require "config.options"
  require "config.keymaps"
  require "config.plugin-manager"
  -- 插件加载完成后立即应用主题（lazy=false 的插件已同步加载）
  require("lib.theme").apply_theme()
  require "config.autocommands"
else
  require "config.options"
  require "config.vscode"
end
