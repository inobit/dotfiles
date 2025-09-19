local status, _ = pcall(require, "dbee")

if status then
  if vim.fn.bufname():match "dbee%-result" then
    -- stylua: ignore start
    vim.keymap.set("n", "L", "zL", { buffer = true, noremap = true, desc = "DBee: zL", silent = true })
    vim.keymap.set("n", "H", "zH", { buffer = true, noremap = true, silent = true, desc = "DBee: zH" })
    -- stylua: ignore end

    -- for result row hover
    vim.bo.buftype = "" -- nofile cannot attach lsp server
  end

  -- -- stylua: ignore start
  vim.keymap.set("n", "<C-l>", "<C-w>l", { buffer = true, noremap = true, silent = true, desc = "DBee: <C-w>l" })
  -- stylua: ignore end
end
