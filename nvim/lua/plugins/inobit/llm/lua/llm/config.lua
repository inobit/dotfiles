local M = {}

local SERVERS = require "llm.servers.const"

local default_servers = {
  {

    server = SERVERS.DEEP_SEEK,
    base_url = "https://api.deepseek.com/v1/chat/completions",
    model = "deepseek-chat",
    stream = true,
    multi_round = true,
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
    mappings = { up = "<C-k>", down = "<C-j>", left = "<C-h>", right = "<C-l>" },
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
      -- 如果 server 已存在，深度合并
      hash[item.server] =
        vim.tbl_deep_extend("force", {}, hash[item.server], item)
    else
      hash[item.server] = item
    end
  end
  return hash
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
  M.options = vim.tbl_deep_extend("force", {}, M.defaults(), options)
  M.options.servers = install_servers(M.options.servers)
end

return M
