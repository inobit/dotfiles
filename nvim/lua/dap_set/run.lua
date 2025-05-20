local function cc(command)
  local file = vim.api.nvim_buf_get_name(0)
  local _, _, basename, _ = string.find(file, "^(.*)%.%a+$")
  local output_filename = basename .. ".out"
  return string.format(command .. " %s -o %s && %s", file, output_filename, output_filename)
end

local commands = {
  clear = "clear",
  python = function()
    if vim.fn.executable "uv" == 1 then
      return "uv run " .. vim.api.nvim_buf_get_name(0)
    else
      return "python -u " .. vim.api.nvim_buf_get_name(0)
    end
  end,
  js = function()
    return "node " .. vim.api.nvim_buf_get_name(0)
  end,
  c = cc,
  cpp = cc,
}

local function run(target_pane, command)
  vim.cmd("silent! !tmux send -t " .. target_pane .. " '" .. command .. "' Enter")
end

vim.keymap.set("n", "<leader>rr", function()
  if vim.bo.filetype == "python" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.python())
  elseif vim.bo.filetype == "javascript" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.js())
  elseif vim.bo.filetype == "c" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.c "cc -g -Wall")
  elseif vim.bo.filetype == "cpp" then
    run(vim.v.count == 0 and 2 or vim.v.count, commands.cpp "g++ -g -Wall")
  end
end, { desc = "run code", silent = true, noremap = true })

vim.keymap.set("n", "<leader>cl", function()
  run(vim.v.count == 0 and 2 or vim.v.count, commands.clear)
end, { desc = "clear print", silent = true, noremap = true })
