return function(opts)
  return function()
    opts = opts or {}
    local actions = require "telescope.actions"
    local state = require "telescope.actions.state"
    local themes = require "telescope.themes"
    local co = coroutine.running()
    local picker_opts = themes.get_dropdown {
      previewer = false,
      cwd = vim.fn.getcwd(),
    }
    local default_file_ignore_patterns = require("telescope.config").values.file_ignore_patterns
    opts.file_ignore_patterns = vim.list_extend(opts.file_ignore_patterns or {}, default_file_ignore_patterns or {})
    require("telescope.builtin").find_files(vim.tbl_extend("force", picker_opts, {
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local entry = state.get_selected_entry()
          coroutine.resume(co, entry.path)
        end)
        return true
      end,
    }, opts))
    return coroutine.yield()
  end
end
