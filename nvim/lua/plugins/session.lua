return {
  {
    "rmagatti/auto-session",
    config = function()
      vim.o.sessionoptions = "blank,buffers,curdir,folds,tabpages,winsize,winpos,localoptions"
      ---@diagnostic disable-next-line: missing-fields
      require("auto-session").setup {
        log_level = "error",
        auto_session_enable_last_session = false,
        auto_session_enabled = true,
        auto_session_root_dir = vim.fn.stdpath "data" .. "/sessions/",
        auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        pre_save_cmds = {
          function()
            local status, nvim_tree_api = pcall(require, "nvim-tree.api")
            if status then
              nvim_tree_api.tree.close()
            end
          end,
        },
        --[[ post_restore_cmds = {
          function()
            if status then
              nvim_tree_api.tree.toggle()
              nvim_tree_api.tree.change_root(vim.fn.getcwd())
              nvim_tree_api.tree.reload()
            end
          end,
        }, ]]
        session_lens = {
          load_on_setup = true,
        },
      }
      vim.keymap.set("n", "<leader>so", require("auto-session.session-lens").search_session, {
        noremap = true,
        desc = "[S]earch session",
      })
    end,
  },
}
