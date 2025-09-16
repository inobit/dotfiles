local M = {}

---@param command string
---@param target_pane? number
function M.run(command, target_pane)
  if vim.env.TMUX then
    if target_pane == nil then
      target_pane = vim.v.count == 0 and 2 or vim.v.count
    end
    vim.cmd("silent! !tmux send -t " .. target_pane .. " '" .. command .. "' Enter")
  else
    vim.cmd("!" .. command)
  end
end

---@param command string | fun(): string
---@param lhs string?
function M.register_run_keymap(command, lhs)
  lhs = lhs or "<leader>rr"
  local buffer = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", lhs, function()
    if type(command) == "function" then
      command = command()
    end
    M.run(command)
  end, { buffer = buffer, desc = "Run: " .. vim.fn.expand "%:e", silent = true, noremap = true })
end

return M
