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

function M.enable_buf_read_status_autocmd(target_bufnr)
  vim.api.nvim_create_augroup("AutoReadonly", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = "AutoReadonly",
    buffer = target_bufnr,
    callback = function()
      vim.o.readonly = true
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = "AutoReadonly",
    buffer = target_bufnr,
    callback = function()
      vim.o.readonly = false
    end,
  })
end

function M.disable_buf_read_status_autocmd()
  pcall(vim.api.nvim_del_augroup_by_name, "AutoReadonly")
end

function M.bind_wins_close(wins)
  vim.api.nvim_create_augroup("AutoCloseWins", { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = "AutoCloseWins",
    callback = function(args)
      local win = tonumber(args.match)
      if vim.tbl_contains(wins, win) then
        -- 遍历窗口表，关闭其他所有窗口
        for _, other_win in ipairs(wins) do
          if other_win ~= win and vim.api.nvim_win_is_valid(other_win) then
            vim.api.nvim_win_close(other_win, true) -- 强制关闭窗口
          end
        end
        pcall(vim.api.nvim_del_augroup_by_name, "AutoCloseWins")
        M.disable_buf_read_status_autocmd()
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

local function generate_random_string(length)
  math.randomseed(os.time())
  local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  local result = {}
  for _ = 1, length do
    local rand_index = math.random(#chars)
    table.insert(result, chars:sub(rand_index, rand_index))
  end
  return table.concat(result)
end

local function is_legal_char(char)
  -- 允许的字符：字母、数字、下划线、连字符和中文字符
  local byte = char:byte() -- 获取字符的 ASCII/Unicode 值
  return (
    (byte >= 48 and byte <= 57) -- 数字 0-9
    or (byte >= 65 and byte <= 90) -- 大写字母 A-Z
    or (byte >= 97 and byte <= 122) -- 小写字母 a-z
    or byte == 95 -- 下划线 _
    or byte == 45 -- 连字符 -
    or (byte >= 0x4e00 and byte <= 0x9fff) -- 中文字符范围
  )
end

function M.generate_session_name(session)
  local LEN = 50
  local m = 0
  local result = ""
  for _, item in ipairs(session) do
    if item.content then
      for i = 1, #item.content do
        local char = item.content:sub(i, i)
        if is_legal_char(char) then
          result = result .. char
          m = m + 1
          if m == LEN then
            return result .. "-" .. generate_random_string(16)
          end
        end
      end
    end
  end
  return result .. "-" .. generate_random_string(16)
end

return M
