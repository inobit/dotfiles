local function get_root_dir()
  return require("lib.utils").get_root_dir(0, "package.json") or vim.fn.getcwd()
end

---@return string
local function js_command_generator()
  local project = require("lib.utils").get_root_dir(0, "package.json")
  if project then
    return "npm run start"
  else
    return "node" .. " " .. vim.fn.expand "%"
  end
end

require("lib.run").register_run_keymap(js_command_generator, { cwd = get_root_dir })
