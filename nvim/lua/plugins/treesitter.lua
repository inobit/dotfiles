return {
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
    init = function()
      -- tree-sitter CLI defaults to cl.exe on Windows; override to gcc
      if vim.fn.has "win32" == 1 then
        vim.env.CC = "gcc"
        if vim.fn.executable "gcc" == 0 then
          vim.notify(
            "[nvim-treesitter] gcc not found, install MinGW: scoop install mingw",
            vim.log.levels.WARN,
            { title = "nvim-treesitter" }
          )
        end
      end
    end,
    opts_extend = { "ensure_installed" },
    build = function()
      require("nvim-treesitter").update(nil, { summary = true })
    end,
    opts = {
      ensure_installed = {
        "bash",
        "cpp",
        "css",
        "diff",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "html",
        "javascript",
        "json",
        "json5",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "dockerfile",
        "latex",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "java",
        "rust",
        "ron", -- rust object notation
        "tmux",
        "make",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      local TS = require "nvim-treesitter"

      -- Setup treesitter (install_dir etc.)
      TS.setup(opts)

      -- Use json5 parser for jsonc filetype (json5 supports comments)
      vim.treesitter.language.register("json5", "jsonc")

      -- Helper: check if a parser is installed
      local function have_parser(lang)
        local installed = TS.get_installed "parsers"
        return vim.tbl_contains(installed, lang)
      end

      -- Install missing parsers from ensure_installed list
      local install = vim.tbl_filter(function(lang)
        return not have_parser(lang)
      end, opts.ensure_installed or {})
      if #install > 0 then
        TS.install(install, { summary = true })
      end

      -- FileType autocommand for enabling features per filetype
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter_filetype", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)

          -- Enabled only for configured lang
          if not vim.tbl_contains(opts.ensure_installed or {}, lang) then
            return
          end

          -- Auto-install missing parser (best-effort, needs reload after install)
          if opts.auto_install and not have_parser(lang) then
            TS.install(lang, { summary = false })
            return
          end

          -- Highlighting (provided by Neovim)
          if opts.highlight and opts.highlight.enable ~= false then
            pcall(vim.treesitter.start, ev.buf)
          end

          -- Indentation (provided by nvim-treesitter, experimental)
          if opts.indent and opts.indent.enable ~= false then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      move = {
        enable = true,
        set_jumps = true,
      },
      select = {
        enable = true,
        lookahead = true,
        selection_modes = {
          ["@function.outer"] = "V",
          ["@parameter.outer"] = "v",
        },
      },
      keys = {
        f = "@function",
        s = "@class",
        a = "@parameter",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter-textobjects").setup(opts)

      local function have_parser(lang)
        local parsers = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", true)
        return #parsers > 0
      end

      local function name_of(query_base)
        local name = query_base:gsub("^@", "")
        return name:sub(1, 1):upper() .. name:sub(2)
      end

      local function attach(buf)
        local ft = vim.bo[buf].filetype
        if not have_parser(ft) then
          return
        end

        -- move: ]f / [f / ]F / [F
        if opts.move and opts.move.enable then
          for short, base in pairs(opts.keys or {}) do
            local outer = base .. ".outer"
            local name = name_of(base)

            vim.keymap.set({ "n", "x", "o" }, "]" .. short, function()
              require("nvim-treesitter-textobjects.move").goto_next_start(outer, "textobjects")
            end, { buffer = buf, desc = "Next " .. name .. " Start", silent = true })

            vim.keymap.set({ "n", "x", "o" }, "]" .. short:upper(), function()
              require("nvim-treesitter-textobjects.move").goto_next_end(outer, "textobjects")
            end, { buffer = buf, desc = "Next " .. name .. " End", silent = true })

            vim.keymap.set({ "n", "x", "o" }, "[" .. short, function()
              require("nvim-treesitter-textobjects.move").goto_previous_start(outer, "textobjects")
            end, { buffer = buf, desc = "Prev " .. name .. " Start", silent = true })

            vim.keymap.set({ "n", "x", "o" }, "[" .. short:upper(), function()
              require("nvim-treesitter-textobjects.move").goto_previous_end(outer, "textobjects")
            end, { buffer = buf, desc = "Prev " .. name .. " End", silent = true })
          end
        end

        -- select: af / if
        if opts.select and opts.select.enable then
          for short, base in pairs(opts.keys or {}) do
            local outer = base .. ".outer"
            local inner = base .. ".inner"
            local name = name_of(base)

            vim.keymap.set({ "x", "o" }, "a" .. short, function()
              require("nvim-treesitter-textobjects.select").select_textobject(outer, "textobjects")
            end, { buffer = buf, desc = "Around " .. name, silent = true })

            vim.keymap.set({ "x", "o" }, "i" .. short, function()
              require("nvim-treesitter-textobjects.select").select_textobject(inner, "textobjects")
            end, { buffer = buf, desc = "Inner " .. name, silent = true })
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter_textobjects", { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      vim.tbl_map(attach, vim.api.nvim_list_bufs())
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
}
