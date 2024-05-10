-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
--[[
     :help runtimepath 中对于搜索路径和文件有相关说明(neovim使用XDG规范 ，默认使用~/.config,~/.local/share之类的，本质上install plugin就是加入到runtimepath中
     plugin的使用一般分为2部分，load，可以理解为启用了，和模块化引用
     load实际上只是执行了plugin_name.nvim/plugin/plugin_name.lua文件，这个执行是自动的，打开nvim时会立即或者滞后（懒加载）执行插件的这个文件
     require plugin，则是引入这个模块，也就是执行了plugin_name.nvim/lua/plugin_name.lua (或plugin_name/init.lua)文件，因为lua目录在package.path中，所以可以require，没有什么魔法
     这2个部分是独立的，并没有相互依赖，只要lua加入了runtimepath，就可以require，并不需要先执行load,只不过load是自动的，所以一般都是先执行了
     分为2个部分的目的也很简单，按需提供，而不是都放在plugin/plugin_name.lua下，startup时全部执行
--]]
