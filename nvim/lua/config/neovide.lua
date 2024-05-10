if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font:h12"
  vim.opt.linespace = 0
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scale_factor = 1.0
  vim.g.neovide_scroll_animation_length = 0
  vim.g.neovide_scroll_animation_far_lines = 1
  vim.g.neovide_hide_mouse_when_typing = false
  if vim.fn.has "win32" == 1 then
    -- 直接打开neovide时修改工作目录
    vim.api.nvim_create_autocmd({ "DirChanged", "VimEnter" }, {
      group = vim.api.nvim_create_augroup("Neovide_CWD", {
        clear = true,
      }),
      callback = function()
        if vim.fn.getcwd() == (vim.env.NEOVIM_GUI_INSTALL_PATH or [[C:\Program Files\Neovide]]) then
          vim.cmd("cd " .. (vim.env.NEOVIM_GUI_CWD or "~"))
        end
      end,
    })
  end
end
