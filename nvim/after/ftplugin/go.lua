-- disable list
vim.opt_local.list = false

local function get_root_dir()
  return require("lib.utils").get_root_dir(0, "go.mod")
end

local function go_run_command()
  local root = get_root_dir()
  if root then
    return "go run ."
  else
    return "go run " .. vim.fn.expand "%"
  end
end

local function go_build_command()
  local root = get_root_dir()
  if root then
    return "go build"
  else
    return "go build " .. vim.fn.expand "%"
  end
end

local function get_cwd()
  return get_root_dir() or vim.fn.getcwd()
end

require("lib.run").register_run_keymap(go_run_command, { cwd = get_cwd })
require("lib.run").register_run_keymap("go test ./...", { cwd = get_cwd, lhs = "<leader>rt" })
require("lib.run").register_run_keymap(go_build_command, { cwd = get_cwd, lhs = "<leader>rb" })
