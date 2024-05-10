local commands = {
  clear = "clear",
  python = function()
    return "python -u " .. vim.api.nvim_buf_get_name(0)
  end,
  js = function()
    return "node " .. vim.api.nvim_buf_get_name(0)
  end,
}

local function run(target_pane, command)
  vim.cmd("silent! !tmux send -t " .. target_pane .. " '" .. command .. "' Enter")
end

vim.keymap.set("n", "<leader>rr", function()
  if vim.bo.filetype == "python" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.python())
  elseif vim.bo.filetype == "javascript" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.js())
  end
end, { desc = "run code", silent = true, noremap = true })

vim.keymap.set("n", "<leader>cl", function()
  run(vim.v.count == 0 and 2 or vim.v.count, commands.clear)
end, { desc = "clear print", silent = true, noremap = true })
