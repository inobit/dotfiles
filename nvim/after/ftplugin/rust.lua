local function get_root_dir()
  local cargo_toml = vim.fn.findfile("Cargo.toml", ".;")
  if cargo_toml == "" then
    return vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(cargo_toml, ":p:h")
end

-- cargo run
require("lib.run").register_run_keymap(function()
  return string.format("cd %s && %s", get_root_dir(), "cargo run")
end, "<leader>rr")
-- cargo check
require("lib.run").register_run_keymap(function()
  return string.format("cd %s && %s", get_root_dir(), "cargo check")
end, "<leader>rc")
