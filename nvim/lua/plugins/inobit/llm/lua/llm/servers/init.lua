local log = require "llm.log"
local io = require "llm.io"
local util = require "llm.util"
local notify = require "llm.notify"
local SERVERS = require "llm.servers.const"
local config = require "llm.config"

local M = {}

-- need set up after config.setup()
local server_selected = config.options.default_server

local function update_auth(server_name, key)
  config.options.servers[server_name].api_key = key
  local _, err =
    io.write_json(config.get_config_file_path(server_name), { api_key = key })
  if err then
    log.error(err)
  end
end

local function input_api_key(server_name)
  local key =
    vim.fn.inputsecret("Enter your " .. server_name .. " API Key: ", "")
  if not util.empty_str(key) then
    return key
  end
end

local function load_api_key(path)
  local json, err = io.read_json(path)
  if err then
    return nil, err
  else
    return json and json.api_key, nil
  end
end

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
    api_key, _ = load_api_key(path)
    if not api_key then
      api_key = input_api_key()
      if not api_key then
        notify.error "A valid key is required!"
        check = false
      else
        update_auth(server_name, api_key)
      end
    else
      config.options.servers[server_name].api_key = api_key
    end
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

function M.get_auth()
  return config.options.servers[server_selected].api_key
end

function M.input_auth(server_name)
  local key = input_api_key(server_name)
  if key then
    update_auth(server_name, key)
  else
    notify.warn "Invalid input! The key is not updated!"
  end
end

return M
