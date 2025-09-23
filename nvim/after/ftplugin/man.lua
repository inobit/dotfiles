vim.api.nvim_win_set_height(0, vim.o.lines)
vim.bo.buftype = "" -- nofile cannot attach lsp server
vim.keymap.set({ "n", "v" }, "K", vim.lsp.buf.hover, { buffer = true, desc = "LSP:  Hover Documentation" })
