return {
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      log_level = "error",
      root_dir = vim.fn.stdpath "data" .. "/sessions/",
      suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
      pre_save_cmds = {
        function()
          local status, nvim_tree_api = pcall(require, "nvim-tree.api")
          if status then
            nvim_tree_api.tree.close()
          end
        end,
      },
      session_lens = {
        load_on_setup = true,
      },
    },
  },
}
