local M = {}

function M.defaults()
  return {
    service = "DeepSeek",
    base_url = "https://api.deepseek.com/v1/chat/completions",
    loading_mark = "...",
    multi_round = true,
    config_dir = vim.fn.stdpath "cache" .. "/my_plugins/llm",
    config_filename = "config.json",
  }
end

M.options = {}

function M.setup(options)
  options = options or {}
  M.options = vim.tbl_deep_extend("force", {}, M.defaults(), options)
end

return M
