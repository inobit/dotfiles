local M = {}

---@param out vim.SystemCompleted
local function handle_output(out)
  if out.code ~= 0 then
    if out.stderr then
      vim.notify(out.stderr, vim.log.levels.ERROR)
    end
  else
    if out.stdout then
      vim.notify(out.stdout, vim.log.levels.INFO)
    end
  end
end

---@param iter Iter
---@param opts? vim.SystemOpts
local function run_chain(iter, opts)
  local command = iter:next()
  if command then
    vim.system(command, opts, function(out)
      vim.schedule(function()
        handle_output(out)
        if out.code == 0 then
          run_chain(iter, opts)
        end
      end)
    end)
  else
    vim.notify "Command finished!"
  end
end

---@param command string[]
---@param opts? vim.SystemOpts
local function run_local(command, opts)
  local command_str = table.concat(command, " ")
  vim.notify("Running " .. command_str)
  ---@type vim.SystemCompleted
  if vim.tbl_contains(command, "&&") then
    local commands = vim.iter(vim.split(command_str, "&&")):map(function(c)
      return vim.split(vim.trim(c), " ")
    end)
    run_chain(commands, opts)
  else
    vim.system(command, opts, function(out)
      vim.schedule(function()
        handle_output(out)
        vim.notify "Command finished!"
      end)
    end)
  end
end

---@param command string | string[]
---@param opts? vim.SystemOpts
---@param target_pane? number
function M.run(command, opts, target_pane)
  local command_tbl = command
  local command_str = command
  if type(command) == "table" then
    command_str = table.concat(command, " ")
  else
    command_tbl = vim.split(command, " ")
  end
  if vim.env.TMUX then
    if target_pane == nil then
      target_pane = vim.v.count == 0 and 2 or vim.v.count
    end
    -- test if pane exists and active
    local panes = vim
      .system({ "tmux", "list-panes", "-F", "#{pane_index},#{window_zoomed_flag}" }, { text = true })
      :wait()
    if panes.stdout:match(target_pane .. ",0") then
      if opts and opts.cwd then
        command_str = "cd " .. opts.cwd .. " && " .. command_str
      end
      vim.system({
        "tmux",
        "send",
        "-t",
        tostring(target_pane),
        command_str --[[@as string]],
        "Enter",
      }, { text = true })
    else
      run_local(command_tbl --[=[@as string[]]=], opts)
    end
  else
    run_local(command_tbl --[=[@as string[]]=], opts)
  end
end

---@class inobit.RunOpts: vim.SystemOpts
---@field lhs? string
---@field cwd? string | fun(): string

---@alias inobit.RunCommand string | string[]

---@param command inobit.RunCommand | fun(): inobit.RunCommand
---@param opts? inobit.RunOpts
function M.register_run_keymap(command, opts)
  opts = vim.tbl_extend("force", { text = true, lhs = "<leader>rr" }, opts or {}) --[[@as inobit.RunOpts]]
  local buffer = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", opts.lhs, function()
    if type(command) == "function" then
      command = command()
    end
    if type(opts.cwd) == "function" then
      opts.cwd = opts.cwd()
    end
    M.run(command, opts)
  end, { buffer = buffer, desc = "Run: " .. vim.fn.expand "%:e", silent = true, noremap = true })
end

return M
