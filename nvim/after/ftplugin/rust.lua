local function get_root_dir()
  return require("lib.utils").get_root_dir(0, "Cargo.toml") or vim.fn.getcwd()
end

-- cargo run
require("lib.run").register_run_keymap("cargo run", { cwd = get_root_dir })
-- cargo check
require("lib.run").register_run_keymap("cargo check", { cwd = get_root_dir, lhs = "<leader>rc" })
-- cargo test
require("lib.run").register_run_keymap("cargo test", { cwd = get_root_dir, lhs = "<leader>rt" })
-- cargo build
require("lib.run").register_run_keymap("cargo build", { cwd = get_root_dir, lhs = "<leader>rb" })
-- cargo clippy
require("lib.run").register_run_keymap("cargo clippy", { cwd = get_root_dir, lhs = "<leader>rl" })
