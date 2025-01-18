-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
--[[
关于插件加载逻辑：
1. nvim启动时会去默认的runtimepath(:h runtimepath)下的相关目录执行脚本（不同目录有不同的作用,比如plugin,ftplugin,color,syntax等等，有些会自动执行有些按需执行）
2. 相关after/目录也在runtimepath中(after中也有系列目录比如plugin,ftplugi,color等等),但是在最后面,runtimepath按顺序执行
3. 相关脚本触发Lazy管理插件,将相关插件目录以及插件目录/after/加入到runtimepath中,同时执行这些runtimepath下的相关目录下的脚本(类似1)
4. after目录(默认和插件的)排在runtimepath后面,最后执行,一般用于后置规则,覆盖一些默认配置
5. require引用模块,调用API,是按照runtimepath中的顺序去对应的lua文件夹下找module.lua或module/init.lua
--]]
