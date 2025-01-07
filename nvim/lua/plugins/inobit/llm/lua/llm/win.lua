local M = {}
local config = require "llm.config"
local servers = require "llm.servers"

function M.create_floating_window(width, height, row, col, winblend, title)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, {
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
  vim.api.nvim_set_option_value("winblend", winblend, { win = win_id })
  vim.cmd(
    string.format(
      "autocmd WinClosed <buffer> silent! execute 'bdelete! %s'",
      bufnr
    )
  )
  return bufnr, win_id
end

local function get_next_float(wins)
  local cur_win = vim.api.nvim_get_current_win()
  local cur_index = nil
  for index, win in ipairs(wins) do
    if win == cur_win then
      cur_index = index
      break
    end
  end
  if not cur_index or cur_index + 1 > #wins then
    return wins[1]
  else
    return wins[cur_index + 1]
  end
end

local function get_prev_float(wins)
  local cur_win = vim.api.nvim_get_current_win()
  local cur_index = nil
  for index, win in ipairs(wins) do
    if win == cur_win then
      cur_index = index
      break
    end
  end
  if not cur_index or cur_index - 1 == 0 then
    return wins[#wins]
  else
    return wins[cur_index - 1]
  end
end

function M.set_vertical_navigate_keymap(up_lhs, down_lhs, buffers, wins)
  for _, buffer in ipairs(buffers) do
    vim.keymap.set("n", up_lhs, function()
      vim.api.nvim_set_current_win(get_prev_float(wins))
    end, { buffer = buffer, noremap = true, silent = true })

    vim.keymap.set("n", down_lhs, function()
      vim.api.nvim_set_current_win(get_next_float(wins))
    end, { buffer = buffer, noremap = true, silent = true })
  end
end

function M.auto_skip_when_insert(source_buf, target_win)
  vim.api.nvim_create_augroup("AutoSkipWhenInsert", { clear = true })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = "AutoSkipWhenInsert",
    buffer = source_buf,
    callback = function()
      if target_win then
        vim.api.nvim_set_current_win(target_win)
        vim.api.nvim_input "<Esc>"
      end
    end,
  })
end

function M.disable_auto_skip_when_insert()
  pcall(vim.api.nvim_del_augroup_by_name, "AutoSkipWhenInsert")
end

function M.register_close_for_wins(wins, group_prefix, callback)
  vim.api.nvim_create_augroup(group_prefix .. "AutoCloseWins", { clear = true })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group_prefix .. "AutoCloseWins",
    callback = function(args)
      local win = tonumber(args.match)
      if vim.tbl_contains(wins, win) then
        -- 遍历窗口表，关闭其他所有窗口
        for _, other_win in ipairs(wins) do
          if other_win ~= win and vim.api.nvim_win_is_valid(other_win) then
            vim.api.nvim_win_close(other_win, true) -- 强制关闭窗口
          end
        end
        pcall(vim.api.nvim_del_augroup_by_name, group_prefix .. "AutoCloseWins")
        if callback then
          callback()
        end
      end
    end,
  })
end

function M.create_chat_win(callback)
  local server = servers.get_server_selected().server
  local chat_win = config.options.chat_win

  local width = math.floor(vim.o.columns * chat_win.width_percentage)

  local response_height =
    math.floor(vim.o.lines * chat_win.response_height_percentage)

  local input_height =
    math.floor(vim.o.lines * chat_win.input_height_percentage)

  local response_top = (vim.o.lines - response_height - input_height) / 2

  local input_top = (vim.o.lines - response_height - input_height) / 2
    + response_height
    + 2

  local left = (vim.o.columns - width) / 2
  local response_buf, response_win = M.create_floating_window(
    width,
    response_height,
    response_top,
    left,
    chat_win.winblend,
    server
  )

  local input_buf, input_win = M.create_floating_window(
    width,
    input_height,
    input_top,
    left,
    chat_win.winblend,
    "input"
  )

  M.set_vertical_navigate_keymap(
    config.options.mappings.up,
    config.options.mappings.down,
    -- 顺序为布局顺序
    { response_buf, input_buf },
    { response_win, input_win }
  )

  vim.api.nvim_set_option_value("cursorline", true, { win = input_win })
  vim.api.nvim_set_option_value("cursorline", true, { win = response_win })
  M.auto_skip_when_insert(response_buf, input_win)
  M.register_close_for_wins({ input_win, response_win }, server, callback)

  return response_buf, response_win, input_buf, input_win
end

local function register_line_move(
  input_buf,
  input_win,
  content_buf,
  content_win
)
  local pos = { 1, 0 }
  vim.api.nvim_set_current_win(input_win)

  vim.keymap.set("n", "j", function()
    local lines = vim.api.nvim_buf_line_count(content_buf)
    if pos[1] + 1 > lines then
      pos[1] = 1
    else
      pos[1] = pos[1] + 1
    end
    vim.api.nvim_win_set_cursor(content_win, pos)
  end, { buffer = input_buf })

  vim.keymap.set("n", "k", function()
    local lines = vim.api.nvim_buf_line_count(content_buf)
    if pos[1] - 1 == 0 then
      pos[1] = lines
    else
      pos[1] = pos[1] - 1
    end
    vim.api.nvim_win_set_cursor(content_win, pos)
  end, { buffer = input_buf })

  return pos
end

local function register_data_handler(input_buf, content_buf, data_handler)
  vim.api.nvim_create_augroup("AutoLoadWhenTextChanged", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = "AutoLoadWhenTextChanged",
    buffer = input_buf,
    callback = function()
      data_handler(input_buf, content_buf)
    end,
  })
end

function M.create_select_picker(
  width_percentage,
  input_height,
  content_height_percentage,
  winblend,
  title,
  data_handler_wrap
)
  local width = math.floor(vim.o.columns * width_percentage)

  local content_height = math.floor(vim.o.lines * content_height_percentage)

  local input_top = (vim.o.lines - input_height - content_height) / 2

  local content_top = (vim.o.lines - input_height - content_height) / 2
    + input_height
    + 2

  local left = (vim.o.columns - width) / 2

  local input_buf, input_win = M.create_floating_window(
    width,
    input_height,
    input_top,
    left,
    winblend,
    title
  )

  local content_buf, content_win = M.create_floating_window(
    width,
    content_height,
    content_top,
    left,
    winblend,
    ""
  )

  local data_handler = data_handler_wrap()
  vim.api.nvim_set_option_value("cursorline", true, { win = content_win })
  vim.api.nvim_set_option_value("wrap", false, { win = content_win })

  M.register_close_for_wins({ input_win, content_win }, title)

  local content_selected =
    register_line_move(input_buf, input_win, content_buf, content_win)

  register_data_handler(input_buf, content_buf, data_handler)

  data_handler(input_buf, content_buf)

  return input_buf, input_win, content_buf, content_win, content_selected
end

return M
