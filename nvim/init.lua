if not vim.g.vscode then
  require "config.env"
  require "config.options"
  require "config.keymaps"
  require "config.plugin-manager"
  require "config.autocommands"
else
  require "config.options"
  require "config.vscode"
end
