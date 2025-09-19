local M = {}

local dbee = require "dbee"
local api = require "dbee.api"

---get selected line json
---@param bufnr number
---@param line number
---@return string | nil
function M.get_selected_row_in_json(bufnr, line)
  local content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  local row_index = content and tonumber(content:match "%s*(%d+)%s*│.*") -- row format
  if row_index then
    -- yank to "" "0
    local register_anony = vim.fn.getreg ""
    local register_zero = vim.fn.getreg "0"
    dbee.store("json", "yank", { from = row_index - 1, to = row_index })
    local json = vim.fn.getreg "0"
    vim.fn.setreg('"', register_anony)
    vim.fn.setreg("0", register_zero)

    --OPTIMIZE: Use decode directly?

    -- remove []
    json = json:gsub("^%[", ""):gsub("%]%s*$", "")
    -- remove space
    local lines = {}
    for l in json:gmatch "([^\n]*)\n?" do
      l = l:gsub("^%s%s", "")
      table.insert(lines, l)
    end
    json = table.concat(lines, "\n")
    return json
  end
end

---@param schema string?
function M.show_current_connection(schema)
  schema = schema or "none"
  local editor = require("dbee.api.state").editor()
  local current_connection = api.core.get_current_connection()
  if current_connection then
    local bar = string.format("%s[%s]", current_connection.name, schema)
    vim.api.nvim_set_option_value(
      "winbar",
      "Current connection: " .. bar,
      ---@diagnostic disable-next-line: invisible
      { win = editor.winid }
    )
  end
end

---@param schema string
local function switch_database(schema)
  if schema then
    dbee.execute("USE " .. schema .. ";")
    if not api.ui.result_get_call().error then
      M.show_current_connection(schema)
      vim.notify("Switched to " .. schema)
    end
  end
end

---@param dml_type  "UPDATE" | "DELETE"
---@param row table
---@return string | nil
local function generate_sql(dml_type, table, row)
  if not row.id then
    vim.notify "No ID, you need to specify the primary key manually."
  end
  local sql
  local id_placeholder = row.id and '"' .. row.id .. '"' or "?"
  if dml_type == "DELETE" then
    sql = string.format("DELETE FROM %s WHERE id = %s;", table, id_placeholder)
  elseif dml_type == "UPDATE" then
    sql = string.format("UPDATE %s SET ? = ? WHERE id = %s;", table, id_placeholder)
  else
    vim.notify "Not supported yet."
  end
  if sql then
    vim.fn.setreg("+", sql)
    vim.notify('Generated SQL to "+ register: ' .. sql)
  end
end

---@param bufnr number
---@param line number
---@return table[]?
function M.code_actions(bufnr, line)
  local current_call = api.ui.result_get_call()
  local actions = {}
  if current_call and not current_call.error then
    -- code action params line is 1-based?
    local row = M.get_selected_row_in_json(bufnr, line - 1)
    if not row then
      return
    end
    row = vim.json.decode(row)
    local query = current_call.query
    if query:upper():match "^SHOW DATABASES;?$" then
      table.insert(actions, {
        title = "Choose database",
        action = function()
          switch_database(vim.api.nvim_get_current_line():match "%s*%d+%s*│%s*(.*)")
        end,
      })
    end
    if query:match "^%s*[Ss][Ee][Ll][Ee][Cc][Tt]" then -- lua pattern has no case-insensitive implementation
      local table_name = query:match ".*%s+[Ff][Rr][Oo][Mm]%s+([^%s]+)[%s;]?"
      if table_name then
        local dml_type = { "DELETE", "UPDATE" }
        for _, dml in ipairs(dml_type) do
          table.insert(actions, {
            title = string.format("Generate %s SQL", dml),
            action = function()
              generate_sql(dml, table_name, row)
            end,
          })
        end
      end
    end
    return actions
  end
end

return M
