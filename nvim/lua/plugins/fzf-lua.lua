return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = function(_, opts)
    local fzf = require "fzf-lua"
    local config = fzf.config
    local actions = fzf.actions

    -- Allow q to close fzf-lua in terminal-normal mode (C-\ C-n)
    -- Does NOT block typing q in the search box
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("fzf-lua-q-close", { clear = true }),
      pattern = "fzf",
      callback = function(args)
        vim.keymap.set("n", "q", function()
          fzf.hide()
        end, { buffer = args.buf, silent = true })
      end,
    })

    -- Quickfix
    config.defaults.keymap.fzf["ctrl-y"] = "select-all+accept"
    config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
    config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
    config.defaults.keymap.fzf["ctrl-g"] = "jump"
    config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
    config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
    config.defaults.keymap.builtin["<c-f>"] = "preview-page-down"
    config.defaults.keymap.builtin["<c-b>"] = "preview-page-up"

    -- Trouble
    local ok, trouble = pcall(require, "trouble.sources.fzf")
    if ok then
      config.defaults.actions.files["ctrl-t"] = trouble.actions.open
    end

    -- Toggle root dir / cwd — adapted without LazyVim.pick dependency
    config.defaults.actions.files["ctrl-r"] = function(_, ctx)
      local o = vim.deepcopy(ctx.__call_opts)
      o.buf = ctx.__CTX.bufnr
      -- Toggle root dir / cwd by comparing current cwd against project root
      local project_root = require("lib.utils").get_root_dir(0)
      local current_cwd = o.cwd or vim.uv.cwd()
      if current_cwd == project_root then
        o.cwd = vim.uv.cwd()
      else
        o.cwd = project_root
      end
      require("fzf-lua")[ctx.__INFO.cmd](o)
    end
    config.set_action_helpstr(config.defaults.actions.files["ctrl-r"], "toggle-root-dir")

    local img_previewer ---@type string[]?
    for _, v in ipairs {
      { cmd = "ueberzug", args = {} },
      { cmd = "chafa", args = { "{file}", "--format=symbols" } },
      { cmd = "viu", args = { "-b" } },
    } do
      if vim.fn.executable(v.cmd) == 1 then
        img_previewer = vim.list_extend({ v.cmd }, v.args)
        break
      end
    end

    return {
      "default-title",
      fzf_colors = true,
      fzf_opts = {
        ["--no-scrollbar"] = true,
      },
      defaults = {
        -- formatter = "path.filename_first",
        formatter = "path.dirname_first",
      },
      previewers = {
        builtin = {
          extensions = {
            ["png"] = img_previewer,
            ["jpg"] = img_previewer,
            ["jpeg"] = img_previewer,
            ["gif"] = img_previewer,
            ["webp"] = img_previewer,
          },
          ueberzug_scaler = "fit_contain",
        },
      },
      -- Custom option to configure vim.ui.select
      ui_select = function(fzf_opts, items)
        return vim.tbl_deep_extend("force", fzf_opts, {
          prompt = " ",
          winopts = {
            title = " " .. vim.trim((fzf_opts.prompt or "Select"):gsub("%s*:%s*$", "")) .. " ",
            title_pos = "center",
          },
        }, fzf_opts.kind == "codeaction" and {
          winopts = {
            layout = "vertical",
            -- height is number of items minus 15 lines for the preview, with a max of 80% screen height
            height = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 4) + 0.5) + 16,
            width = 0.5,
            preview = not vim.tbl_isempty(vim.lsp.get_clients { bufnr = 0, name = "vtsls" }) and {
              layout = "vertical",
              vertical = "down:15,border-top",
              hidden = "hidden",
            } or {
              layout = "vertical",
              vertical = "down:15,border-top",
            },
          },
        } or {
          winopts = {
            width = 0.5,
            -- height is number of items, with a max of 80% screen height
            height = math.floor(math.min(vim.o.lines * 0.8, #items + 4) + 0.5),
          },
        })
      end,
      winopts = {
        preview = {
          scrollchars = { "┃", "" },
        },
      },
      files = {
        cwd_prompt = false,
        actions = {
          ["alt-i"] = { actions.toggle_ignore },
          ["alt-h"] = { actions.toggle_hidden },
        },
      },
      grep = {
        actions = {
          ["alt-i"] = { actions.toggle_ignore },
          ["alt-h"] = { actions.toggle_hidden },
        },
      },
      lsp = {
        symbols = {
          symbol_hl = function(s)
            return "TroubleIcon" .. s
          end,
          symbol_fmt = function(s)
            return s:lower() .. "\t"
          end,
          child_prefix = false,
        },
        code_actions = {
          previewer = vim.fn.executable "delta" == 1 and "codeaction_native" or nil,
        },
      },
    }
  end,
  config = function(_, opts)
    if opts[1] == "default-title" then
      -- use the same prompt for all pickers for profile `default-title`
      local function fix(t)
        t.prompt = t.prompt ~= nil and " " or nil
        for _, v in pairs(t) do
          if type(v) == "table" then
            fix(v)
          end
        end
        return t
      end
      opts = vim.tbl_deep_extend("force", fix(require "fzf-lua.profiles.default-title"), opts)
      opts[1] = nil
    end
    require("fzf-lua").setup(opts)
  end,
  init = function()
    -- Override vim.ui.select to use fzf-lua (lazy-loads on first use)
    -- The first call lazy-loads fzf-lua, registers the picker, then delegates.
    -- register_ui_select itself replaces vim.ui.select with fzf-lua's handler,
    -- so subsequent calls go directly to fzf-lua without this wrapper.
    vim.ui.select = function(...)
      require("lazy").load { plugins = { "fzf-lua" } }
      local fzf = require("lazy.core.config").plugins["fzf-lua"]
      local plugin_opts = fzf.opts or {}
      if type(plugin_opts) == "function" then
        plugin_opts = fzf:opts {} or {}
      end
      require("fzf-lua").register_ui_select(plugin_opts.ui_select or nil)
      -- register_ui_select has replaced vim.ui.select with fzf-lua's handler
      return vim.ui.select(...)
    end
  end,
  -- stylua: ignore start
  keys = {
    -- Fzf terminal keymaps
    { "<c-j>", "<c-j>", ft = "fzf", mode = "t", nowait = true },
    { "<c-k>", "<c-k>", ft = "fzf", mode = "t", nowait = true },
    -- git
    { "<leader>fgc", "<cmd>FzfLua git_commits<CR>", desc = "Commits" },
    { "<leader>fgd", "<cmd>FzfLua git_diff<cr>", desc = "Git Diff (files)" },
    { "<leader>fgs", "<cmd>FzfLua git_status<CR>", desc = "Status" },
    { "<leader>fgS", "<cmd>FzfLua git_stash<cr>", desc = "Git Stash" },
    { "<leader>fgb", "<cmd>FzfLua git_blame<cr>", desc = "Git Blame" },
    -- search
    { '<leader>s"', "<cmd>FzfLua registers<cr>", desc = "Registers" },
    { "<leader>s/", "<cmd>FzfLua search_history<cr>", desc = "Search History" },
    { "<leader>sl", "<cmd>FzfLua lines<cr>", desc = "Buffer Lines" },
    { "<leader>s;", "<cmd>FzfLua commands<cr>", desc = "Commands" },
    { "<leader>s:", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
    { "<leader>sb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Switch Buffer" },
    { "<leader>se", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics" },
    { "<leader>sE", "<cmd>FzfLua diagnostics_document<cr>", desc = "Buffer Diagnostics" },
    { "<leader>sf", function() require("fzf-lua").files({ cwd = require("lib.utils").get_root_dir(0) or vim.uv.cwd() }) end, desc = "Find Files (Root Dir)" },
    { "<leader>sF", function() require("fzf-lua").files({ cwd = vim.uv.cwd() }) end, desc = "Find Files (cwd)" },
    { "<leader>sg", function() require("fzf-lua").live_grep({ cwd = require("lib.utils").get_root_dir(0) or vim.uv.cwd() }) end, desc = "Grep (Root Dir)" },
    { "<leader>sG", function() require("fzf-lua").live_grep({ cwd = vim.uv.cwd() }) end, desc = "Grep (cwd)" },
    { "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "Help Pages" },
    { "<leader>sH", "<cmd>FzfLua highlights<cr>", desc = "Search Highlight Groups" },
    { "<leader>sj", "<cmd>FzfLua jumps<cr>", desc = "Jumplist" },
    { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Key Maps" },
    { "<leader>sL", "<cmd>FzfLua loclist<cr>", desc = "Location List" },
    { "<leader>sM", "<cmd>FzfLua man_pages<cr>", desc = "Man Pages" },
    { "<leader>sm", "<cmd>FzfLua marks<cr>", desc = "Jump to Mark" },
    { "<leader>su", "<cmd>FzfLua resume<cr>", desc = "Resume" },
    { "<leader>sq", "<cmd>FzfLua quickfix<cr>", desc = "Quickfix List" },
    { "<leader>sw", function() require("fzf-lua").grep_cword({ cwd = require("lib.utils").get_root_dir(0) or vim.uv.cwd() }) end, desc = "Word (Root Dir)" },
    { "<leader>sW", function() require("fzf-lua").grep_cword({ cwd = vim.uv.cwd() }) end, desc = "Word (cwd)" },
    { "<leader>sw", function() require("fzf-lua").grep_visual({ cwd = require("lib.utils").get_root_dir(0) or vim.uv.cwd() }) end, mode = "x", desc = "Selection (Root Dir)" },
    { "<leader>sW", function() require("fzf-lua").grep_visual({ cwd = vim.uv.cwd() }) end, mode = "x", desc = "Selection (cwd)" },
    { "<leader>sT", "<cmd>FzfLua colorschemes<cr>", desc = "Colorscheme with Preview" },
    { "<leader>ss", function() require("fzf-lua").lsp_document_symbols() end, desc = "Goto Symbol" },
    { "<leader>sS", function() require("fzf-lua").lsp_live_workspace_symbols() end, desc = "Goto Symbol (Workspace)" },
    { "<leader>sc", function() require("fzf-lua").files({ cwd = vim.fn.stdpath("config"), prompt_title = "Dotfiles" }) end, desc = "Find Config File" },
    { "<leader>sr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
    { "<leader>sR", function() require("fzf-lua").oldfiles({ cwd = vim.uv.cwd() }) end, desc = "Recent (cwd)" },
  -- stylua: ignore end
  },
}
