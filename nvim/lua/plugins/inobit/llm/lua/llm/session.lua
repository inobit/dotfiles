local M = {}

local util = require "llm.util"
local servers = require "llm.servers"
local notify = require "llm.notify"
local config = require "llm.config"
local io = require "llm.io"

-- 对话历史
local session_name = nil
local session = {}
-- 最后一次响应在response_buf的区域
local response_last_points = {}

function M.get_session()
  return session
end

function M.record_start_point(bufnr)
  response_last_points.start_row, response_last_points.start_col =
    util.get_last_char_position(bufnr)
end

function M.record_end_point(bufnr)
  response_last_points.end_row, response_last_points.end_col =
    util.get_last_char_position(bufnr)
end

function M.write_request_to_session(message)
  table.insert(session, message)
end

function M.write_response_to_session(server_role, bufnr)
  M.record_end_point(bufnr)
  local response_last = {
    role = server_role or servers.get_server_selected().server,
    content = table.concat(
      vim.api.nvim_buf_get_text(
        bufnr,
        response_last_points.start_row,
        response_last_points.start_col,
        response_last_points.end_row,
        response_last_points.end_col,
        {}
      ),
      "\n"
    ),
  }
  table.insert(session, response_last)
  response_last = {}
  response_last_points = {}
end

function M.get_session_file_path(server, name)
  if server and name then
    return config.options.base_config_dir
      .. "/"
      .. config.options.session_dir
      .. "/"
      .. server
      .. "/"
      .. name
      .. ".json"
  else
    return nil
  end
end

function M.clear_session(save)
  if save then
    M.save_session()
  end
  session = {}
  session_name = nil
end

function M.save_session()
  if not session or #session == 0 then
    notify.info "No session to save."
    return
  end
  if not session_name then
    session_name = util.generate_session_name(session)
  end
  local _, err = io.write_json(
    M.get_session_file_path(servers.get_server_selected().server, session_name),
    session
  )
  if err then
    notify.error(err)
  else
    notify.info("Session saved: " .. session_name)
  end
end

function M.load_session(name)
  local json, err = io.read_json(
    M.get_session_file_path(servers.get_server_selected().server, name)
  )
  if err then
    notify.error(err)
  else
    session = json
    session_name = name
  end
end

function M.resume_session(bufnr)
  if bufnr and session and #session > 0 then
    for _, item in ipairs(session) do
      local lines = vim.split(item.content, "\n")
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "" })
    end
  end
end
return M
