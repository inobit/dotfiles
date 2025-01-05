local M = {}

local util = require "llm.util"
local io = require "llm.io"
local notify = require "llm.notify"
local config = require "llm.config"

local active_job = nil

-- key
local api_key = nil

function M.input_api_key()
  local key = vim.fn.inputsecret(
    "Enter your " .. config.options.service .. " API Key: ",
    ""
  )
  if util.empty_str(key) then
    return
  end
  local size, err = io.write_json(util.get_config_path(), { api_key = key })
  if err then
    notify.error(err)
  end
  if size > 0 then
    api_key = key
  end
end

function M.load_api_key()
  local json, err = io.read_json(util.get_config_path())
  if err then
    notify.error(err)
  end
  if json and not util.empty_str(json.api_key) then
    api_key = json.api_key
  end
end

function M.check_options()
  local check = true
  if not config.options.service then
    notify.error "A service name is required!"
    check = false
  end
  if not config.options.base_url then
    notify.error "A service URL is required!"
    check = false
  end
  if not config.options.config_dir then
    notify.error "A config directory is required!"
    check = false
  end
  if not config.options.config_filename then
    notify.error "A config filename is required!"
    check = false
  end
  if not api_key then
    M.load_api_key()
    if not api_key then
      M.input_api_key()
      if not api_key then
        notify.error "A valid key is required!"
        check = false
      end
    end
  end
  return check
end

-- 对话历史
local messages = {}
-- 最后一次响应
local response_last = {}
-- 最后一次响应在response_buf的区域
local response_last_points = {}

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
  -- 显示 DeepSeek 回复
  local lines = vim.split(content, "\n")
  vim.api.nvim_buf_set_text(M.response_buf, row, col, row, col, lines)
  util.set_cursor(M.response_win, M.response_buf)
end

local function enable_input_enter()
  vim.keymap.set("n", "<CR>", function()
    M.submit()
  end, { buffer = M.input_buf, noremap = true, silent = true })
end

local function disable_input_enter()
  vim.keymap.del("n", "<CR>", { buffer = M.input_buf })
end

local function handle_prev()
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
  vim.api.nvim_buf_set_lines(
    M.response_buf,
    line_count - 1,
    line_count,
    false,
    {}
  )
  response_last_points.start_row, response_last_points.start_col =
    util.get_last_char_position(M.response_buf)
end

local function handle_post()
  active_job = nil
  first_response = false
  response_last_points.end_row, response_last_points.end_col =
    util.get_last_char_position(M.response_buf)
  if config.options.multi_round then
    if response_last.role then
      response_last.content = (response_last.content or "")
        .. table.concat(
          vim.api.nvim_buf_get_text(
            M.response_buf,
            response_last_points.start_row,
            response_last_points.start_col,
            response_last_points.end_row,
            response_last_points.end_col,
            {}
          ),
          "\n"
        )
      table.insert(messages, response_last)
      response_last = {}
      response_last_points = {}
    end
  else
    messages = {}
  end
  enable_input_enter()
  vim.api.nvim_buf_set_lines(M.response_buf, -1, -1, false, { "" }) -- 添加空行
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
        response_last.role = data.choices[1].delta.role
        response_last.content = content
      end
    end
    if content and content ~= vim.NIL then
      write_to_buf(content)
    end
  end)
end

local function build_deepseek_request(input)
  table.insert(messages, { role = "user", content = input })
  local args = {
    config.options.base_url,
    "-N",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    "Authorization: Bearer " .. api_key,
    "-d",
    vim.json.encode {
      model = "deepseek-chat",
      messages = messages,
      stream = true,
    },
  }
  return args
end

local function send_request(input)
  local args = build_deepseek_request(input)
  if active_job then
    active_job:shutdown()
    active_job = nil
  end
  active_job = io.curl(args, handle_prev, handle_response, handle_post)
  active_job:start()
end

-- 处理用户输入
local function handle_input(input_buf)
  local input_lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local input = table.concat(input_lines, "\n")
  if input == "" then
    return
  end

  -- 清空输入行
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})
  disable_input_enter()
  -- 发送请求到LLM
  send_request(input)
end

local function set_navigate_keymap()
  -- 设置导航映射
  vim.keymap.set("n", "<C-j>", function()
    util.switch_to_next_float(M.input_win, M.response_win)
  end, { buffer = M.input_buf, noremap = true, silent = true })

  vim.keymap.set("n", "<C-k>", function()
    util.switch_to_next_float(M.input_win, M.response_win)
  end, { buffer = M.input_buf, noremap = true, silent = true })

  vim.keymap.set("n", "<C-j>", function()
    util.switch_to_next_float(M.input_win, M.response_win)
  end, { buffer = M.response_buf, noremap = true, silent = true })

  vim.keymap.set("n", "<C-k>", function()
    util.switch_to_next_float(M.input_win, M.response_win)
  end, { buffer = M.response_buf, noremap = true, silent = true })
end

-- 启动对话
function M.start_chat()
  local check = M.check_options()
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
    config.options.service
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

  set_navigate_keymap()
  enable_input_enter()
  util.bind_wins_close(input_win, response_win)
end

-- 提交输入
function M.submit()
  if not M.input_buf or not M.response_buf then
    return
  end
  handle_input(M.input_buf)
end

function M.clear_history_message()
  messages = {}
end

return M
