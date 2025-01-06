local M = {}

local util = require "llm.util"
local io = require "llm.io"
local notify = require "llm.notify"
local config = require "llm.config"
local session = require "llm.session"
local servers = require "llm.servers"

local active_job = nil
local server_role = nil

local function switch_enter_key(bufnr, enable)
  if enable then
    vim.keymap.set("n", "<CR>", function()
      M.submit()
    end, { buffer = bufnr, noremap = true, silent = true })
  else
    vim.keymap.del(
      "n",
      "<CR>",
      { buffer = bufnr, noremap = true, silent = true }
    )
  end
end

local function handle_line(line, process_data)
  if not line then
    return false
  end
  local json = line:match "^data: (.+)$"
  if json then
    if json == "[DONE]" then
      return true
    end
    local data = vim.json.decode(json)
    vim.schedule(function()
      process_data(data)
    end)
  end
  return false
end

local function write_to_buf(content)
  local row, col = util.get_last_char_position(M.response_buf)
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_text(M.response_buf, row, col, row, col, lines)
  util.set_cursor(M.response_win, M.response_buf)
end

local function handle_response_prev()
  -- 在响应缓冲区中显示等待消息
  vim.api.nvim_buf_set_lines(
    M.response_buf,
    -1,
    -1,
    false,
    { config.options.loading_mark }
  )
end

-- 第一次响应时的处理
local first_response = false
local function handle_first_response()
  first_response = true
  local line_count = vim.api.nvim_buf_line_count(M.response_buf)
  -- 删除等待信息
  vim.api.nvim_buf_set_lines(
    M.response_buf,
    line_count - 1,
    line_count,
    false,
    { "" }
  )
  session.record_start_point(M.response_buf)
end

-- 后置处理器
local function handle_response_post()
  session.write_response_to_session(server_role, M.response_buf)
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, { "" }) -- 添加空行
  switch_enter_key(M.input_buf, true)
  active_job = nil
  server_role = nil
  first_response = false
end

local function handle_response(err, out)
  if not first_response then
    vim.schedule(handle_first_response)
  end
  if err then
    vim.schedule(function()
      notify.error(err, err)
    end)
    return
  end

  handle_line(out, function(data)
    local content
    if data.choices and data.choices[1] and data.choices[1].delta then
      content = data.choices[1].delta.content
      if data.choices[1].delta.role then
        server_role = data.choices[1].delta.role
      end
    end
    if content and content ~= vim.NIL then
      write_to_buf(content)
    end
  end)
end

local function send_request(input)
  local args = servers.get_server_selected().build_request(input)
  if active_job then
    active_job:shutdown()
    active_job = nil
  end
  active_job =
    io.curl(args, handle_response_prev, handle_response, handle_response_post)
  active_job:start()
end

-- 处理用户输入
local function handle_input()
  local input_lines = vim.api.nvim_buf_get_lines(M.input_buf, 0, -1, false)
  local input = table.concat(input_lines, "\n")
  if input == "" then
    return
  end

  -- 清空输入行
  vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, {})
  switch_enter_key(M.input_buf, false)
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, input_lines)
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, { "" })
  util.set_cursor(M.response_win, M.response_buf)
  -- 发送请求到LLM
  local message = { role = "user", content = input }
  session.write_request_to_session(message)
  -- 多轮发送整个session
  if servers.get_server_selected().multi_round then
    send_request(session.get_session())
  else
    -- 只发送本次input
    send_request(message)
  end
end

-- 启动对话
function M.start_chat()
  local check = servers.check_options(servers.get_server_selected().server)
  if not check then
    return
  end
  local width = math.floor(vim.o.columns * 0.7)
  local response_height = math.floor(vim.o.lines * 0.5)
  local input_height = 5
  local col = (vim.o.columns - width) / 2
  local response_buf, response_win = util.create_floating_window(
    width,
    response_height,
    (vim.o.lines - response_height - input_height) / 2,
    col,
    servers.get_server_selected().server
  )

  local input_buf, input_win = util.create_floating_window(
    width,
    input_height,
    (vim.o.lines - response_height - input_height) / 2 + response_height + 2,
    col,
    "input"
  )

  -- 保存缓冲区引用
  M.input_buf = input_buf
  M.input_win = input_win
  M.response_buf = response_buf
  M.response_win = response_win

  -- 参数顺序为实际从上到下
  util.set_vertical_navigate_keymap(
    config.options.mappings.up,
    config.options.mappings.down,
    { response_buf, input_buf },
    { response_win, input_win }
  )
  switch_enter_key(input_buf, true)
  util.auto_skip_when_insert(response_buf, input_win)
  util.register_close_for_wins { input_win, response_win }
  session.resume_session(response_buf)
  util.set_cursor(response_win, response_buf)
end

-- 提交输入
function M.submit()
  if not M.input_buf or not M.response_buf then
    return
  end
  handle_input()
end

return M
