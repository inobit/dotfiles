local M = {}

local util = require "llm.util"
local io = require "llm.io"
local notify = require "llm.notify"
local config = require "llm.config"
local session = require "llm.session"
local servers = require "llm.servers"
local win = require "llm.win"

local active_job = nil
local server_role = nil

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
  util.scroll_to_end(M.response_win, M.response_buf)
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
  if M.register_enter_handler then
    M.register_enter_handler()
  end
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
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, input_lines)
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, { "" })
  util.scroll_to_end(M.response_win, M.response_buf)
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

local function clear_chat()
  M.response_buf = nil
  M.response_win = nil
  M.input_buf = nil
  M.input_win = nil
  win.disable_auto_skip_when_insert()
end

-- 启动对话
function M.start_chat()
  local check = servers.check_options(servers.get_server_selected().server)
  if not check then
    return
  end
  -- create chat window
  M.response_buf, M.response_win, M.input_buf, M.input_win, M.register_enter_handler =
    win.create_chat_win(M.submit, clear_chat)
  session.resume_session(M.response_buf)
  util.scroll_to_end(M.response_win, M.response_buf)
end

-- 提交输入
function M.submit()
  if not M.input_buf or not M.response_buf then
    return
  end
  handle_input()
end

function M.save()
  session.save_session()
end

function M.clear(save)
  if not M.input_buf or not M.response_buf then
    return
  end
  session.clear_session(save)
  vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(M.response_buf, 0, -1, false, {})
end

function M.new()
  session.clear_session(true)
  if not M.input_buf or not M.response_buf then
    M.start_chat()
  else
    vim.api.nvim_buf_set_lines(M.input_buf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(M.response_buf, 0, -1, false, {})
  end
end

function M.input_auth()
  local server = servers.get_server_selected().server
  local path = config.get_config_file_path(server)
  local key, err = server.input_api_key(server, path)
  if err then
    notify.warn(err)
  end
  if key then
    servers.update_auth(key)
  end
end

function M.select_sessions()
  session.create_session_picker_win(function()
    if M.input_buf and M.response_buf then
      session.resume_session(M.response_buf)
      if M.input_win then
        vim.api.nvim_set_current_win(M.input_win)
      end
    else
      M.start_chat()
    end
  end)
end
return M
