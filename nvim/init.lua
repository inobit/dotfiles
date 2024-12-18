if not vim.g.vscode then
  require "config.options"
  require "config.keymaps"
  require "config.filetype"
  require "config.plugin-manager"
  require "config.autocommands"
  require "config.neovide"
  pcall(require, "config.local-options")
else
  require "config.options"
  require "config.vscode"
end
