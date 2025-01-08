local M = {}

local SERVERS = require "llm.servers.const"

local default_servers = {
  {

    server = SERVERS.DEEP_SEEK,
    base_url = "https://api.deepseek.com/v1/chat/completions",
    model = "deepseek-chat",
    stream = true,
    multi_round = true,
    user_role = "user",
  },
}

function M.defaults()
  return {
    servers = {},
    default_server = SERVERS.DEEP_SEEK,
    loading_mark = "...",
    base_config_dir = vim.fn.stdpath "cache" .. "/inobit/llm",
    config_dir = "config",
    session_dir = "session",
    config_filename = "config.json",
    chat_win = {
      width_percentage = 0.8,
      response_height_percentage = 0.7,
      input_height_percentage = 0.1,
      winblend = 5,
    },
    session_picker_win = {
      width_percentage = 0.5,
      input_height = 1,
      content_height_percentage = 0.3,
      winblend = 5,
    },
    server_picker_win = {
      width_percentage = 0.4,
      input_height = 1,
      content_height_percentage = 0.3,
      winblend = 5,
    },
  }
end

local function install_servers(servers)
  servers = servers or {}
  local hash = {}
  for _, item in ipairs(default_servers) do
    hash[item.server] = item
  end

  for _, item in ipairs(servers) do
    if hash[item.server] then
      hash[item.server] =
        vim.tbl_deep_extend("force", {}, hash[item.server], item)
    else
      hash[item.server] = item
    end
  end
  return hash
end

function M.install_win_cursor_move_keymap(mappings)
  M.options.win_cursor_move_mappings = mappings
end

function M.get_config_file_path(server_name)
  if server_name then
    return M.options.base_config_dir
      .. "/"
      .. M.options.config_dir
      .. "/"
      .. server_name
      .. "/"
      .. M.options.config_filename
  else
    return nil
  end
end

M.options = {}

function M.setup(options)
  options = options or {}
  M.options = vim.tbl_deep_extend(
    "force",
    { win_cursor_move_mappings = M.options.win_cursor_move_mappings },
    M.defaults(),
    options
  )
  M.options.servers = install_servers(M.options.servers)
end

return M
