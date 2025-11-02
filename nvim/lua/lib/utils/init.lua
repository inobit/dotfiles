local M = {}

---@param source? string | integer
---@param marker? string | string[]
---@return string?
function M.get_root_dir(source, marker)
  source = source or 0
  marker = marker or ".git"
  local root_dir = vim.fs.root(source, marker)
  return root_dir
end

return M
