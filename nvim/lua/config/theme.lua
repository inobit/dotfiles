local status, _ = pcall(require, "catppuccin")
if status then
  vim.cmd.colorscheme "catppuccin-frappe"
end
vim.cmd.hi "Comment gui=none"
