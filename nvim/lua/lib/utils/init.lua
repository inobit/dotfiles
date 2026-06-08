local M = {}

local level_to_hl = {
  [vim.log.levels.ERROR] = "DiagnosticVirtualLinesError",
  [vim.log.levels.WARN] = "DiagnosticVirtualLinesWarn",
  [vim.log.levels.INFO] = "DiagnosticVirtualLinesInfo",
}

--- Fancy notification wrapper, idea borrowed from blink.nvim
---@param lvl number
---@param ... any Message can be a table with highlights (e.g. { "foo", "Error" })
---  or a vararg of strings/numbers to be sent to string.format
function M.notify(lvl, ...)
  local arg1 = (...)
  local msg = type(arg1) == "table" and arg1 or string.format(...)
  local hl = level_to_hl[lvl] or "DiagnosticVirtualLinesHint"

  local header_hl, chunks
  if type(msg) == "table" then
    for i, v in ipairs(msg) do
      if type(v) ~= "table" or not v[2] then
        msg[i] = { type(v) ~= "table" and tostring(v) or v[1], "" }
      end
    end
    header_hl, chunks = hl, msg
  else
    header_hl, chunks = "LineNr", { { msg, hl } }
  end

  table.insert(chunks, 1, { "[Nvim]", header_hl })
  table.insert(chunks, 2, { " " })
  local function nvim_echo()
    vim.api.nvim_echo(chunks, true, {
      verbose = false,
      err = lvl == vim.log.levels.ERROR,
    })
  end
  if vim.in_fast_event() then
    vim.schedule(nvim_echo)
  else
    nvim_echo()
  end
end

function M.info(...)
  M.notify(vim.log.levels.INFO, ...)
end

function M.warn(...)
  M.notify(vim.log.levels.WARN, ...)
end

function M.error(...)
  M.notify(vim.log.levels.ERROR, ...)
end

---@param source? string | integer
---@param marker? string | string[]
---@return string?
function M.get_root_dir(source, marker)
  source = source or 0
  marker = marker or ".git"
  return vim.fs.root(source, marker)
end

---@param path string
---@return string?
function M.exists(path)
  local normalized = vim.fs.normalize(path)
  local stat = vim.uv.fs_stat(normalized)
  return stat and normalized or nil
end

---@param cwd? string
---@param noerr? boolean
---@return string?
function M.git_root(cwd, noerr)
  local cmd = { "git", "rev-parse", "--show-toplevel" }
  if cwd then
    table.insert(cmd, 2, "-C")
    table.insert(cmd, 3, vim.fn.expand(cwd))
  end
  local ok, res = pcall(function()
    return vim.system(cmd):wait()
  end)
  if not ok or not res then
    if not noerr then
      M.info(res)
    end
    return nil
  end
  return (assert(res.stdout):gsub("\n$", ""))
end

---@return boolean
function M.is_root()
  return vim.uv.getuid() == 0
end

--- Get visually selected text
---@param nl_literal? boolean If true, use literal "\n" instead of actual newlines
---@return string
function M.get_visual_selection(nl_literal)
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      cscol, cecol = 0, 999
    end
  else
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  if cerow < csrow then
    csrow, cerow = cerow, csrow
  end
  if cecol < cscol then
    cscol, cecol = cecol, cscol
  end
  local lines = vim.fn.getline(csrow, cerow) ---@cast lines string[]
  if #lines <= 0 then
    return ""
  end
  lines[#lines] = string.sub(lines[#lines], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, nl_literal and "\\n" or "\n")
end

--- OSC52 copy to system clipboard (useful in tmux/SSH)
---@param ... any Format string and args
M.osc52printf = function(...)
  local str = string.format(...)
  local base64 = vim.base64.encode(str)
  local osc52str = string.format("\x1b]52;c;%s\x07", base64)
  local bytes = vim.fn.chansend(vim.v.stderr, osc52str)
  assert(bytes > 0)
  M.info("[OSC52] %d chars copied (%d bytes)", #str, bytes)
end

--- Simple vim.ui.input wrapper
---@param prompt string
---@return string?
function M.input(prompt)
  local res
  local ok, _ = pcall(vim.ui.input, { prompt = prompt }, function(input)
    res = input
  end)
  return ok and res or nil
end

---Execute a shell command with sudo privileges
---@param cmd string The shell command to execute
---@param filepath? string The file path for display purposes
---@param print_output? boolean Whether to show success notification
---@return boolean
function M.sudo_exec(cmd, filepath, print_output)
  vim.fn.inputsave()
  local password = vim.fn.inputsecret("Password: ")
  vim.fn.inputrestore()
  if not password or #password == 0 then
    M.warn("Invalid password, sudo aborted")
    return false
  end
  local ok, res = pcall(function()
    return vim.system({ "sh", "-c",
      string.format("echo '%s' | sudo -p '' -S %s", password, cmd) }):wait()
  end)
  if not ok or res.code ~= 0 then
    M.warn(not ok and res or assert(res).stderr)
    return false
  else
    if print_output then
      M.info([["%s" written
%s]], filepath, res.stderr)
    end
    return true
  end
end

---Write current buffer with sudo privileges
---@param tmpfile? string Temporary file path
---@param filepath? string Target file path
function M.sudo_write(tmpfile, filepath)
  if not tmpfile then
    tmpfile = vim.fn.tempname()
  end
  if not filepath then
    filepath = vim.fn.expand("%")
  end
  if not filepath or #filepath == 0 then
    M.warn("E32: No file name")
    return
  end
  -- store alt buffer
  local alt_buf = vim.fn.bufnr("#")
  -- `bs=1048576` is equivalent to `bs=1M` for GNU dd or `bs=1m` for BSD dd
  -- Both `bs=1M` and `bs=1m` are non-POSIX
  local cmd = string.format(
    "dd if=%s of=%s bs=1048576",
    vim.fn.shellescape(tmpfile),
    vim.fn.shellescape(filepath)
  )
  -- no need to check error as this fails the entire function
  vim.api.nvim_exec2(string.format("write! %s", tmpfile), { output = true })
  if M.sudo_exec(cmd, filepath, true) then
    vim.cmd("e!")
  end
  -- restore alt buf
  if alt_buf and vim.api.nvim_buf_is_valid(alt_buf) then
    vim.fn.setreg("#", alt_buf)
  end
  vim.fn.delete(tmpfile)
end

return M
