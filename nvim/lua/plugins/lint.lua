return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  -- need mason add bin to PATH
  dependencies = { "mason-org/mason.nvim" },
  opts = {
    -- Event to trigger linters
    events = { "BufWritePost", "BufReadPost", "InsertLeave" },
    linters_by_ft = {
      lua = { "selene" },
      python = {
        --[[ "ruff", ]]
        "mypy",
      },
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      html = { "htmlhint" },
      css = { "stylelint" },
      scss = { "stylelint" },
      sass = { "stylelint" },
      less = { "stylelint" },
      json = { "jsonlint" },
      sh = { "shellcheck" },
      dockerfile = { "hadolint" },
      sql = { "sqlfluff" },
      yaml = { "yamllint" },
      -- Use the "*" filetype to run linters on all filetypes.
      -- ['*'] = { 'global linter' },
      -- Use the "_" filetype to run linters on filetypes that don't have other linters configured.
      -- ['_'] = { 'fallback linter' },
      -- ["*"] = { "typos" },
    },
    -- or add custom linters.
    ---@type table<string,table>
    linters = {
      selene = {
        -- dynamically enable/disable linters based on the context.
        condition = function(ctx)
          return vim.fs.find({ "selene.toml" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      eslint_d = {
        condition = function(ctx)
          return vim.fs.find({
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.yaml",
            ".eslintrc.yml",
            ".eslintrc.json",
          }, { path = ctx.filename, upward = true })[1]
        end,
      },
      htmlhint = {
        condition = function(ctx)
          return vim.fs.find({ ".htmlhintrc" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      stylelint = {
        condition = function(ctx)
          return vim.fs.find({
            "stylelint.config.js",
            ".stylelintrc.js",
            "stylelint.config.mjs",
            ".stylelintrc.mjs",
            "stylelint.config.cjs",
            ".stylelintrc.cjs",
            ".stylelintrc.json",
            ".stylelintrc.yml",
            ".stylelintrc.yaml",
            ".stylelintrc",
          }, { path = ctx.filename, upward = true })[1]
        end,
      },
      yamllint = {
        condition = function(ctx)
          return vim.fs.find({ ".yamllint", ".yamllint.yaml", ".yamllint.yml" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      ruff = {
        condition = function(ctx)
          return vim.fs.find({ "pyproject.toml", "ruff.toml", ".ruff.toml" }, { path = ctx.filename, upward = true })[1]
        end,
      },
      mypy = {
        getPythonPath = function()
          return vim.b[vim.api.nvim_get_current_buf()].python_bin
        end,
        default_args = {
          "--show-column-numbers",
          "--show-error-end",
          "--hide-error-context",
          "--no-color-output",
          "--no-error-summary",
          -- "--no-pretty",
        },
      },
      sqlfluff = {
        condition = function(ctx)
          return vim.fs.find({ ".sqlfluff" }, { path = ctx.filename, upward = true })[1]
        end,
      },
    },
  },
  config = function(_, opts)
    local M = {}

    local lint = require "lint"
    for name, linter in pairs(opts.linters) do
      -- backup mypy default args
      if name == "mypy" then
        linter.default_args = vim.tbl_get(lint, "linters", "mypy", "args") or linter.default_args
      end
      if type(linter) == "table" and type(lint.linters[name]) == "table" then
        ---@diagnostic disable-next-line: param-type-mismatch
        lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
      else
        lint.linters[name] = linter
      end
    end
    lint.linters_by_ft = opts.linters_by_ft

    function M.debounce(ms, fn)
      local timer = vim.uv.new_timer()
      return function(...)
        local argv = { ... }
        timer:start(ms, 0, function()
          timer:stop()
          vim.schedule_wrap(fn)(unpack(argv))
        end)
      end
    end

    function M.lint()
      -- Use nvim-lint's logic first:
      -- * checks if linters exist for the full filetype first
      -- * otherwise will split filetype by "." and add all those linters
      -- * this differs from conform.nvim which only uses the first filetype that has a formatter
      local names = lint._resolve_linter_by_ft(vim.bo.filetype)

      -- Create a copy of the names table to avoid modifying the original.
      names = vim.list_extend({}, names)

      -- Add fallback linters.
      if #names == 0 then
        vim.list_extend(names, lint.linters_by_ft["_"] or {})
      end

      -- Add global linters.
      vim.list_extend(names, lint.linters_by_ft["*"] or {})

      -- Filter out linters that don't exist or don't match the condition.
      local ctx = { filename = vim.api.nvim_buf_get_name(0) }
      ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
      names = vim.tbl_filter(function(name)
        local linter = lint.linters[name]
        if not linter then
          print("Linter not found: " .. name, { title = "nvim-lint" })
        end
        ---@diagnostic disable-next-line: undefined-field
        return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
      end, names)

      -- use for lualine
      vim.b.lint_names = names
      -- Run linters.
      if #names > 0 then
        -- config mypy
        if vim.tbl_contains(names, "mypy") then
          local linter = lint.linters["mypy"]
          ---@diagnostic disable-next-line: undefined-field
          local pythonPath = linter.getPythonPath and linter.getPythonPath()
          if pythonPath then
            -- set python executable
            ---@diagnostic disable-next-line: undefined-field
            linter.args = vim.list_extend(vim.deepcopy(linter.default_args), { "--python-executable", pythonPath })
          end
        end

        lint.try_lint(names)
      end
    end

    vim.api.nvim_create_autocmd(opts.events, {
      group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      callback = M.debounce(100, M.lint),
    })
  end,
}
