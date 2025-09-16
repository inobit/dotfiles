vim.bo.textwidth = 120
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.tabstop = 4

vim.b.python_bin = require("lib.python").get_python_bin(vim.api.nvim_get_current_buf())

vim.lsp.config("pyright", {
  on_attach = function(client)
    require("lib.python").set_pyright_python_path(client, vim.b.python_bin)
  end,
})
