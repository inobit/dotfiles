local io = require "llm.io"
local notify = require "llm.notify"
local SERVERS = require "llm.servers.const"
local config = require "llm.config"

local M = {}

local server_selected = SERVERS.DEEP_SEEK

local function check_common_options(server_name)
  local check = true
  if not config.options.servers[server_name].base_url then
    notify.error "A server URL is required!"
    check = false
  end
  return check
end

local function check_api_key(server_name)
  local api_key = config.options.servers[server_name].api_key
  local path = config.get_config_file_path(server_name)
  local check = true
  if not api_key then
    api_key, _ = io.load_api_key(path)
    if not api_key then
      api_key, _ = io.input_api_key(server_name, path)
      if not api_key then
        notify.error "A valid key is required!"
        check = false
      end
    end
  end
  if check then
    config.options.servers[server_name].api_key = api_key
  end
  return check
end

local function build_deepseek_request(input)
  local server_name = SERVERS.DEEP_SEEK
  local args = {
    config.options.servers[server_name].base_url,
    "-N",
    "-X",
    "POST",
    "-H",
    "Content-Type: application/json",
    "-H",
    "Authorization: Bearer " .. config.options.servers[server_name].api_key,
    "-d",
    vim.json.encode {
      model = config.options.servers[server_name].model,
      messages = input,
      stream = config.options.servers[server_name].stream,
    },
  }
  return args
end

-- TODO: add more check
local function check_deepseek_options()
  config.options.servers[SERVERS.DEEP_SEEK].build_request =
    build_deepseek_request
  return true
end

function M.check_options(server_name)
  local check = true
  if not check_common_options(server_name) then
    check = false
  end
  if server_name == SERVERS.DEEP_SEEK then
    if not check_deepseek_options() then
      check = false
    end
  end
  if not check_api_key(server_name) then
    check = false
  end
  return check
end

function M.get_server_selected()
  return config.options.servers[server_selected]
end

function M.set_server_selected(server_name)
  server_selected = server_name
end

return M
