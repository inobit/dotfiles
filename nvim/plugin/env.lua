---@param app "nvim" | "mason"
---@param python_version? string
local function setup_nvim_venv(app, python_version)
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

_, _, vim.g.python3_host_prog = setup_nvim_venv("nvim", "3.12")
local _, mason_python_bin, _ = setup_nvim_venv("mason", "3.12")
if mason_python_bin then
  if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
    vim.env.PATH = mason_python_bin .. ";" .. vim.env.PATH
  else
    vim.env.PATH = mason_python_bin .. ":" .. vim.env.PATH
  end
end
