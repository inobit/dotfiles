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
          -- don't save NvimTree
          local status, nvim_tree_api = pcall(require, "nvim-tree.api")
          if status then
            local all_buffers = vim.api.nvim_list_bufs()
            for _, bufnr in ipairs(all_buffers) do
              if vim.bo[bufnr].filetype == "NvimTree" then
                vim.api.nvim_buf_delete(bufnr, { force = true })
                nvim_tree_api.tree.close()
              end
            end
          end
        end,
      },
      session_lens = {
        load_on_setup = true,
      },
    },
  },
}
