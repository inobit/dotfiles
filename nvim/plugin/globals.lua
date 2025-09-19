P = function(v)
  print(vim.inspect(v))
  return v
end

RELOAD = function(...)
  return require("plenary.reload").reload_module(...)
end

R = function(name)
  RELOAD(name)
  return require(name)
end

vim.api.nvim_create_user_command("Re", function(opts)
  if #opts.fargs > 0 then
    RELOAD(unpack(opts.fargs))
  end
end, { desc = "Reload module", nargs = "*" })
