local config = require "llm.config"

local M = {}

-- 创建浮动窗口
function M.create_floating_window(width, height, row, col, title)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = title,
    title_pos = "center",
    focusable = true,
  })
  return buf, win
end

function M.get_last_char_position(bufnr)
  -- 获取缓冲区的总行数
  local last_line = vim.api.nvim_buf_line_count(bufnr)

  -- 获取最后一行的内容
  local last_line_content =
    vim.api.nvim_buf_get_lines(bufnr, last_line - 1, last_line, false)[1]

  -- 计算最后一行的字符数
  local last_char_col = #last_line_content

  -- 返回最后一个字符的位置（行号, 列号）
  return last_line - 1, last_char_col
end

function M.bind_wins_close(win1, win2)
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win1),
    callback = function()
      if vim.api.nvim_win_is_valid(win2) then
        vim.api.nvim_win_close(win2, true)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win2),
    callback = function()
      if vim.api.nvim_win_is_valid(win1) then
        vim.api.nvim_win_close(win1, true)
      end
    end,
  })
end

function M.switch_to_next_float(win1, win2)
  local wins = { win1, win2 }
  local cur_win = vim.api.nvim_get_current_win()
  -- 遍历所有窗口，寻找下一个浮动窗口
  for _, win in ipairs(wins) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" and win ~= cur_win then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

function M.set_cursor(win, bufnr)
  local win_height = vim.api.nvim_win_get_height(win)
  -- 计算是否需要滚动
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  if total_lines > win_height then
    -- 设置光标到缓冲区最后一行，触发滚动
    vim.api.nvim_win_set_cursor(win, { total_lines, 0 })
  end
end

function M.handle_exit_code(code)
  local msg
  if code == 0 then
    msg = "Request succeeded!"
  elseif code == 1 then
    msg = "Unsupported protocol or malformed URL."
  elseif code == 6 then
    msg = "Could not resolve host."
  elseif code == 7 then
    msg = "Failed to connect to host."
  elseif code == 22 then
    msg = "HTTP error (e.g., 404 Not Found, 401 Unauthorized)."
  elseif code == 28 then
    msg = "Request timed out."
  else
    msg = "Request failed with unknown exit code: " .. code
  end
  if code ~= 0 then
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

function M.empty_str(str)
  return str == nil or str:match "^%s*$" ~= nil
end

function M.get_config_path()
  if
    config.options.config_dir
    and config.options.service
    and config.options.config_filename
  then
    return config.options.config_dir
      .. "/"
      .. config.options.service
      .. "/"
      .. config.options.config_filename
  else
    return nil
  end
end

return M
