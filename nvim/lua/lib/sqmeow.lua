--- sqmeow 相关工具：scratchpad 上的 code actions
--- 1. 弹窗显示光标处表的 schema（调 sqmeow structure 弹窗）
--- 2. EXPLAIN 当前语句
--- 3. EXPLAIN ANALYZE 当前语句（仅 SELECT，ANALYZE 会真实执行）
local M = {}

--- 光标位置：0-based 行 + 字节列
---@return integer row, integer col
local function cursor_pos()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return line - 1, col
end

--- 获取 buffer 的 sql parser（失败返回 nil，如 parser 未安装）
---@param bufnr integer
---@return table|nil
local function get_parser(bufnr)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "sql")
  if ok then
    return parser
  end
end

--- 去引号（双引号/反引号/方括号）
---@param text string
---@return string
local function unquote(text)
  return (text:gsub('^["`%[]*(.-)["`%]]*$', "%1"))
end

--- 光标处的 object_reference（表引用）节点，拆分出 schema 与 relation
--- 列引用（u.id）解析为 field 节点不会命中；别名（FROM users u 中的 u）也不触发
---@param bufnr integer
---@param row integer 0-based 行
---@param col integer 0-based 字节列
---@return string|nil schema
---@return string|nil relation
local function table_at_cursor(bufnr, row, col)
  local parser = get_parser(bufnr)
  if not parser then
    return
  end
  local root = parser:parse()[1]:root()
  local node = root:named_descendant_for_range(row, col, row, col)
  while node and node:type() ~= "object_reference" do
    node = node:parent()
  end
  if not node then
    return
  end
  local text = vim.treesitter.get_node_text(node, bufnr)
  local parts = vim.split(text, ".", { plain = true })
  for i, part in ipairs(parts) do
    parts[i] = unquote(part)
  end
  if #parts >= 2 then
    return parts[1], parts[2]
  end
  return nil, parts[1]
end

--- 光标所在的 statement 节点文本（不含结尾分号）
---@param bufnr integer
---@param row integer 0-based 行
---@param col integer 0-based 字节列
---@return string|nil
local function statement_at_cursor(bufnr, row, col)
  local parser = get_parser(bufnr)
  if not parser then
    return
  end
  local root = parser:parse()[1]:root()
  local node = root:named_descendant_for_range(row, col, row, col)
  while node and node:type() ~= "statement" do
    node = node:parent()
  end
  if not node then
    return
  end
  return vim.treesitter.get_node_text(node, bufnr)
end

--- scratchpad 的 code actions（sql/mysql/plsql）
--- 依赖 sqmeow 活跃连接：无连接时不出动作
---@param bufnr integer
---@return table[]|nil
function M.scratch_actions(bufnr)
  local ok, connection_api = pcall(require, "sqmeow.api.connection")
  if not ok then
    return
  end
  local connection = connection_api.target(bufnr)
  if not connection then
    return
  end

  local row, col = cursor_pos()
  local actions = {}

  -- 1. 弹窗显示光标处表的 schema
  local schema, relation = table_at_cursor(bufnr, row, col)
  if relation and relation ~= "" then
    -- 裸表名时按方言补默认 schema：mysql 用连接的 database，sqlite 用 main，pg 用 public
    schema = schema or connection.database
    if not schema then
      if connection.dialect == "sqlite" then
        schema = "main"
      elseif connection.dialect == "postgres" then
        schema = "public"
      end
    end
    table.insert(actions, {
      title = schema and ("Show schema of " .. schema .. "." .. relation) or ("Show schema of " .. relation),
      action = function()
        require("sqmeow.rpc.events").ensure()
        require("sqmeow.ui.structure").open(connection.id, schema, relation)
      end,
    })
  end

  -- 2/3. EXPLAIN / EXPLAIN ANALYZE
  local statement = statement_at_cursor(bufnr, row, col)
  if statement then
    local query = require "sqmeow.api.query"
    table.insert(actions, {
      title = "EXPLAIN statement",
      action = function()
        query.execute("EXPLAIN " .. statement, { source_buf = bufnr })
      end,
    })
    -- ANALYZE 会真实执行语句（写语句会真的写库），仅对 SELECT 提供
    if statement:match "^%s*[Ss][Ee][Ll][Ee][Cc][Tt]" then
      table.insert(actions, {
        title = "EXPLAIN ANALYZE statement (executes for real)",
        action = function()
          query.execute("EXPLAIN ANALYZE " .. statement, { source_buf = bufnr })
        end,
      })
    end
  end

  return #actions > 0 and actions or nil
end

return M
