local breakpoints = require "dap.breakpoints"
local filename = "breakpoints.json"
local filedir = vim.fn.stdpath "data" .. "/dap/"
local breakpoints_fp = filedir .. filename

local function file_exist(file_path)
  if vim.fn.isdirectory(filedir) ~= 1 then
    vim.fn.mkdir(filedir, "p")
  end
  local f = io.open(file_path, "r")
  return f ~= nil and io.close(f)
end

function _G.store_breakpoints(clear)
  local bps = {}

  local load_bps_raw = file_exist(breakpoints_fp) and io.open(breakpoints_fp, "r"):read "*a"
  if load_bps_raw and string.len(load_bps_raw) ~= 0 then -- empty string causes an error when decoding json
    bps = vim.fn.json_decode(load_bps_raw)
  end

  if clear then
    for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
      bps[vim.api.nvim_buf_get_name(bufrn)] = nil
    end
  else
    local breakpoints_by_buf = breakpoints.get()
    for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
      bps[vim.api.nvim_buf_get_name(bufrn)] = breakpoints_by_buf[bufrn]
    end
  end
  local fp = io.open(breakpoints_fp, "w")
  if fp ~= nil then
    fp:write(vim.fn.json_encode(bps))
    fp:close()
  end
end

function _G.load_breakpoints()
  if not file_exist(breakpoints_fp) then
    return
  end
  local content = io.open(breakpoints_fp, "r"):read "*a"
  if string.len(content) == 0 then
    return
  end
  local bps = vim.fn.json_decode(content)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local file_name = vim.api.nvim_buf_get_name(buf)
    if bps and bps[file_name] ~= nil then
      for _, bp in pairs(bps[file_name]) do
        local line = bp.line
        local opts = {
          condition = bp.condition,
          log_message = bp.logMessage,
          hit_condition = bp.hitCondition,
        }
        breakpoints.set(opts, tonumber(buf), line)
      end
    end
  end
end

function _G.toggle_breakpoints()
  if not vim.tbl_isempty(breakpoints.get()) then
    store_breakpoints(false)
    require("dap").clear_breakpoints()
  else
    load_breakpoints()
  end
end
