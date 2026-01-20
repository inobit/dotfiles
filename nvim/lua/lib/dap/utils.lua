local M = {}
local breakpoints = require "dap.breakpoints"
local Path = require "plenary.path"

---@type Path
local breakpoints_fp = Path:new(vim.fn.stdpath "data", "dap", "breakpoints.json")

---@param file_path Path
local function file_exist(file_path)
  vim.fn.mkdir(file_path:parent().filename, "p")
  local f = io.open(file_path.filename, "r")
  return f ~= nil and io.close(f)
end

function M.store_breakpoints(clear)
  local bps = {}

  local load_bps_raw = file_exist(breakpoints_fp) and io.open(breakpoints_fp.filename, "r"):read "*a"
  if load_bps_raw and string.len(load_bps_raw) ~= 0 then -- empty string causes an error when decoding json
    bps = vim.fn.json_decode(load_bps_raw)
  end

  if clear then
    --TODO: session manage
    for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
      bps[vim.api.nvim_buf_get_name(bufrn)] = nil
    end
  else
    local breakpoints_by_buf = breakpoints.get()
    for _, bufrn in ipairs(vim.api.nvim_list_bufs()) do
      bps[vim.api.nvim_buf_get_name(bufrn)] = breakpoints_by_buf[bufrn]
    end
  end
  local fp = io.open(breakpoints_fp.filename, "w")
  if fp ~= nil then
    fp:write(vim.fn.json_encode(bps))
    fp:close()
  end
end

function M.load_breakpoints()
  if not file_exist(breakpoints_fp) then
    return
  end
  local content = io.open(breakpoints_fp.filename, "r"):read "*a"
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

function M.toggle_breakpoints()
  if not vim.tbl_isempty(breakpoints.get()) then
    M.store_breakpoints(false)
    require("dap").clear_breakpoints()
  else
    M.load_breakpoints()
  end
end

---@param direction "next"|"prev"
function M.gotoBreakpoint(direction)
  local _breakpoints = breakpoints.get()
  if vim.tbl_isempty(_breakpoints) then
    vim.notify("No breakpoints set", vim.log.levels.WARN)
    return
  end

  local points = {}
  local current_bufnr_points = {}
  local current_bufnr = vim.api.nvim_get_current_buf()
  for bufnr, buffer in pairs(_breakpoints) do
    for _, point in ipairs(buffer) do
      table.insert(points, { bufnr = bufnr, line = point.line })
      if bufnr == current_bufnr then
        table.insert(current_bufnr_points, { bufnr = bufnr, line = point.line })
      end
    end
  end

  ---@alias DapPoint {bufnr:number, line:number}

  ---@param current_pos  DapPoint
  ---@param container DapPoint[]
  ---@return DapPoint | nil
  local function get_next_point(current_pos, container)
    for i = 1, #container do
      local isAtBreakpointI = container[i].bufnr == current_pos.bufnr and container[i].line == current_pos.line
      if isAtBreakpointI then
        local nextIdx = direction == "next" and i + 1 or i - 1
        if nextIdx > #container then
          nextIdx = 1
        end
        if nextIdx == 0 then
          nextIdx = #container
        end
        return container[nextIdx]
      end
    end
  end

  ---@type DapPoint | nil
  local nextPoint

  local current_pos = { bufnr = current_bufnr, line = vim.api.nvim_win_get_cursor(0)[1] }

  nextPoint = get_next_point(current_pos, points)

  if not nextPoint then
    -- if current buffer has no breakpoints, fallback to the first point in global scope
    if not current_bufnr_points then
      nextPoint = points[1]
    else
      -- if current buffer has breakpoints, get the next breakpoint in current buffer scope
      table.insert(current_bufnr_points, current_pos)
      table.sort(current_bufnr_points, function(a, b)
        return a.line < b.line
      end)
      nextPoint = get_next_point(current_pos, current_bufnr_points)
    end
  end -- Fallback to first if none found

  ---@cast nextPoint -nil
  vim.cmd(string.format("buffer +%s %s", nextPoint.line, nextPoint.bufnr))
end

return M
