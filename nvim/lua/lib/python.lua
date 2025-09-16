local M = {}

---@param app "nvim" | "mason"
---@param python_version? string
function M.setup_nvim_venv(app, python_version)
  local version = python_version or "3.12"
  local uv_exists = vim.fn.executable "uv" == 1

  if not uv_exists then
    vim.notify("the uv command does not exist. please install uv first.", vim.log.levels.ERROR)
    return false
  end

  local data_path = vim.fn.stdpath "data"

  -- determine the path separator based on the operating system
  local is_windows = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1
  local path_sep = is_windows and "\\" or "/"
  local venv_path = data_path .. path_sep .. "venv" .. path_sep .. app
  local venv_python_bin = venv_path .. path_sep .. ".venv" .. path_sep .. (is_windows and "Scripts" or "bin")
  local venv_python = venv_python_bin .. path_sep .. (is_windows and "python.exe" or "python")

  -- check if the virtual environment directory exists
  local venv_exists = vim.fn.isdirectory(venv_path) == 1

  if not venv_exists then
    -- create  virtual environment
    vim.notify(string.format("creating %s virtual environment...", app), vim.log.levels.INFO)
    local create_cmd =
      string.format("uv venv --python %s %s", version, vim.fn.shellescape(venv_path .. path_sep .. ".venv"))
    local create_result = vim.fn.system(create_cmd)

    if vim.v.shell_error ~= 0 then
      vim.notify("virtual environment creation failed: " .. create_result, vim.log.levels.ERROR)
      return false
    end

    vim.notify("virtual environment created successfully: " .. venv_path, vim.log.levels.INFO)

    if app == "nvim" then
      -- install pynvim
      vim.notify("installing pynvim...", vim.log.levels.INFO)

      local current_dir = vim.fn.getcwd()

      -- switch to the virtual environment directory
      vim.fn.chdir(venv_path)

      -- execute the install command
      local install_cmd = "uv pip install pynvim"
      local install_result = vim.fn.system(install_cmd)

      -- return to the previous directory
      vim.fn.chdir(current_dir)

      if vim.v.shell_error ~= 0 then
        vim.notify("installing pynvim failed: " .. install_result, vim.log.levels.ERROR)
        return false
      end

      vim.notify("pynvim installation successful", vim.log.levels.INFO)
    end

    return true, venv_python_bin, venv_python
  else
    -- is exists
    return true, venv_python_bin, venv_python
  end
end

---@param bufnr? number
---@return string | nil
function M.get_python_bin(bufnr)
  local cmd = "uv python find"
  if bufnr then
    cmd = string.format("%s --directory %s", cmd, vim.fn.fnamemodify(vim.fn.bufname(bufnr), ":p:h"))
  end
  local bin = vim.trim(vim.fn.system(cmd))
  if vim.v.shell_error ~= 0 then
    local path = os.getenv "virtual_env"
      or os.getenv "VIRTUAL_ENV"
      or vim.fn.getcwd() .. (vim.fn.has "win32" == 1 and "\\.venv" or "/.venv")
    if path ~= nil and vim.fn.isdirectory(path) == 1 then
      bin = path .. (vim.fn.has "win32" == 1 and "\\Scripts\\python.exe" or "/bin/python")
    else
      vim.notify("No python available", vim.log.levels.WARN)
    end
  end
  return bin
end

---@param client vim.lsp.Client
---@param path string
function M.set_pyright_python_path(client, path)
  if client.name == "pyright" then
    if client.settings then
      client.settings.python =
        vim.tbl_deep_extend("force", client.settings.python --[[@as table]], { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
    end
    client:notify("workspace/didChangeConfiguration", { settings = nil })
  end
end

return M
