local function get_root_dir()
  return require("lib.utils").get_root_dir(0, "Cargo.toml") or vim.fn.getcwd()
end

-- cargo run
require("lib.run").register_run_keymap("cargo run", { cwd = get_root_dir })
-- cargo check
require("lib.run").register_run_keymap("cargo check", { cwd = get_root_dir, lhs = "<leader>rc" })
