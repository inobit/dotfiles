local M = {}

-- options
function M.setup(opts)
  require("llm.config").setup(opts)
  local server = require "llm.api"
  local notify = require "llm.notify"

  vim.api.nvim_create_user_command("LLM", function(options)
    local args = options.fargs
    local command = args[1]
    if command == nil then
      server.start_chat()
    elseif command == "Chat" then
      server.start_chat()
    elseif command == "Auth" then
      server.input_auth()
    elseif command == "Submit" then
      server.submit()
    elseif command == "New" then
      server.new()
    elseif command == "Clear" then
      server.clear(false)
    elseif command == "Save" then
      server.save()
    elseif command == "Sessions" then
      server.select_sessions()
    elseif command == "Delete" then --delete session
      if server.delete_session then
        server.delete_session()
      end
    elseif command == "Rename" then -- rename session
      if server.rename_session then
        server.rename_session()
      end
    else
      notify.warn "Invalid LLM command"
    end
  end, { desc = "llm chat", nargs = "?" })
end

return M
