local pylib = require "lib.python"

_, _, vim.g.python3_host_prog = pylib.setup_nvim_venv("nvim", vim.g.nvim_python_version or "3.12")
local _, mason_python_bin, _ = pylib.setup_nvim_venv("mason", vim.g.mason_python_version or "3.12")
if mason_python_bin then
  if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
    vim.env.PATH = mason_python_bin .. ";" .. vim.env.PATH
  else
    vim.env.PATH = mason_python_bin .. ":" .. vim.env.PATH
  end
end
