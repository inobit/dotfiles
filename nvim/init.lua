if not vim.g.vscode then
  require "config.options"
  pcall(require, "config.local-options")
  require "config.keymaps"
  require "config.filetype"
  require "config.plugin-manager"
  require "config.autocommands"
  require "config.globals"
  require "config.neovide"
else
  require "config.options"
  require "config.vscode"
end
