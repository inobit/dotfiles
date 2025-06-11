local pylib = require "lib.python"

_, _, vim.g.python3_host_prog = pylib.setup_nvim_venv("nvim", "3.12")
local _, mason_python_bin, _ = pylib.setup_nvim_venv("mason", "3.12")
if mason_python_bin then
  if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
    vim.env.PATH = mason_python_bin .. ";" .. vim.env.PATH
  else
    vim.env.PATH = mason_python_bin .. ":" .. vim.env.PATH
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("find_python_bin", { clear = true }),
  -- pattern = "python",
  callback = function(event)
    if vim.bo[event.buf].filetype == "python" then
      local bin = pylib.get_python_bin()
      if bin ~= nil then
        pylib.set_lsp_python_path(event.buf, bin)
      end
    end
  end,
})
