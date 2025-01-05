local M = {}

-- options
function M.setup(opts)
  local server = require "llm.api"
  local notify = require "llm.notify"
  require("llm.config").setup(opts)

  vim.api.nvim_create_user_command("LLM", function(opts)
    local args = opts.fargs
    local command = args[1]
    if command == nil then
      server.start_chat()
    elseif command == "Chat" then
      server.start_chat()
    elseif command == "Auth" then
      server.input_api_key()
    elseif command == "Submit" then
      server.submit()
    elseif command == "Clear" then
      server.clear_history_message()
    else
      notify.warn "Invalid LLM command"
    end
  end, { desc = "llm chat", nargs = "?" })
end

return M
