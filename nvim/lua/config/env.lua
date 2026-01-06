-- load .env file
require("lib.dotenv").eval(vim.fs.joinpath(vim.fn.stdpath "config", ".env"), true)

-- python env
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

-- obsidian env
vim.g.obsidian_vault = vim.fn.expand(vim.env.OBSIDIAN_VAULT or "~/documents/notes/")

---ai controll,if not set all ai engine will be used for cmp source
vim.g.ai_inline_completion_engine = vim.env.AI_INLINE_COMPLETION_ENGINE or "supermaven"

-- linux
-- #!/bin/bash
-- /usr/bin/curl --no-buffer "$@"
-- windows
-- @echo off
-- "C:\Windows\System32\curl.exe" --no-buffer %*
vim.g.plenary_curl_bin_path = vim.fn.expand(vim.env.CURL_BIN_PATH or "~/.local/bin/mycurl") -- use --no-buffer

-- set self-build DeepLX
vim.g.my_deeplx = vim.env.USE_DEEPLX == "true" or false

vim.g.my_deeplx_base_url = string.format("https://api.deeplx.org/%s/translate", vim.env.LINUX_DO_DEEPLX_API_KEY)
