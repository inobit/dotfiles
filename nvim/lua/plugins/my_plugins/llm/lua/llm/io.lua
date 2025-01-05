local log = require "llm.log"
local util = require "llm.util"
local Path = require "plenary.path"
local Job = require "plenary.job"
local uv = vim.loop
local default_mod = 438 --0666

local M = {}

function M.curl(args, handle_prev, handle_response, handle_post)
  local active_job = Job:new {
    command = "curl",
    args = args,
    on_start = function()
      handle_prev()
    end,
    on_stdout = function(_, out)
      handle_response(nil, out)
    end,
    on_stderr = function(err, _)
      handle_response(err, nil)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        util.handle_exit_code(code)
        handle_post()
      end)
    end,
  }
  return active_job
end

function M.read_json(path)
  local fd, err, errcode = uv.fs_open(path, "r", default_mod)
  if err or not fd then
    if errcode == "ENOENT" then
      return nil, errcode
    end
    log.error("could not open ", path, ": ", err)
    return nil, errcode
  end

  local stat, err, errcode = uv.fs_fstat(fd)
  if err or not stat then
    uv.fs_close(fd)
    log.error("could not stat ", path, ": ", err)
    return nil, errcode
  end

  local contents, err, errcode = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if err then
    log.error("could not read ", path, ": ", err)
    return nil, errcode
  end

  local ok, json = pcall(vim.fn.json_decode, contents)
  if not ok then
    log.error("could not parse json in ", path, ": ", err)
    return nil, json
  end

  return json, nil
end

function M.write_json(path, json)
  local ok, text = pcall(vim.fn.json_encode, json)
  if not ok then
    log.error("could not encode JSON ", path, ": ", text)
    return nil, text
  end

  local parent = Path:new(path):parent().filename
  local ok, err = pcall(vim.fn.mkdir, parent, "p")
  if not ok then
    log.error("could not create directory ", parent, ": ", err)
    return nil, err
  end

  local fd, err, errcode = uv.fs_open(path, "w+", default_mod)
  if err or not fd then
    log.error("could not open ", path, ": ", err)
    return nil, errcode
  end

  local size, err, errcode = uv.fs_write(fd, text, 0)
  uv.fs_close(fd)
  if err then
    log.error("could not write ", path, ": ", err)
    return nil, errcode
  end

  return size, nil
end

return M
