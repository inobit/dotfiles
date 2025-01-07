local M = {}

function M.get_last_char_position(bufnr)
  local last_line = vim.api.nvim_buf_line_count(bufnr)
  local last_line_content =
    vim.api.nvim_buf_get_lines(bufnr, last_line - 1, last_line, false)[1]
  -- 计算最后一行的字符数
  local last_char_col = #last_line_content
  -- 返回最后一个字符的位置（行号, 列号）
  return last_line - 1, last_char_col
end

function M.set_cursor(win, bufnr)
  local win_height = vim.api.nvim_win_get_height(win)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  if total_lines > win_height then
    -- 设置光标到缓冲区最后一行，触发滚动
    vim.api.nvim_win_set_cursor(win, { total_lines, 0 })
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
    or (byte >= 0x4e00 and byte <= 0x9fa5) -- 中文字符范围
  )
end

function M.generate_session_name(session)
  local LEN = 50
  local m = 0
  local result = ""
  for _, item in ipairs(session) do
    if item.content then
      for i = 1, #item.content do
        --BUG: 不符合预期
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
