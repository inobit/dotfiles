return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    -- event = "VeryLazy",
    dependencies = {
      -- install LSPs and related tools to stdpath for neovim
      "mason-org/mason.nvim",
      -- show progress bar, notification, etc.
      { "j-hui/fidget.nvim", opts = {} },
      -- signatures reinforce
      "ray-x/lsp_signature.nvim",
    },
    init = function()
      local lsp_servers = require("plugins.mason.tools").lsp_servers
      -- enable lsp server right now
      for _, server in ipairs(lsp_servers) do
        vim.lsp.enable(server) -- jdtls is configured by nvim-java
      end

      -- lsp config
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      -- Configuration from the result of merging all tables returned by lsp/<name>.lua files in 'runtimepath' for a server of name.
      vim.lsp.config("*", {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          if client.name == "ruff" then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end
          require("lsp_signature").on_attach({
            hint_enable = false,
            handler_opts = { border = "none" },
          }, bufnr)
        end,
      })
    end,
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lspconfig", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            if mode == nil then
              mode = "n"
            end
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          --  To jump back, press <C-t>.
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
          -- Find references for the word under your cursor.
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
          -- Jump to the implementation of the word under your cursor. Useful when your language has ways of declaring types without an actual implementation.
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map("gT", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map("gs", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
          -- Fuzzy find all the symbols in your current workspace
          --  Similar to document symbols, except searches over your whole project.
          map("gS", require("telescope.builtin").lsp_workspace_symbols, "[W]orkspace [S]ymbols")
          -- quickfix
          map("gq", require("telescope.builtin").quickfix, "[Q]uickfix")

          -- Rename the variable under your cursor
          --  Most Language Servers support renaming across files, etc.
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map("ga", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("gA", function()
            vim.lsp.buf.code_action {
              apply = true,
              context = {
                only = { "source" },
                diagnostics = {},
              },
            }
          end, "[S]ource [A]ction")
          -- Opens a popup that displays documentation about the word under your cursor
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>K", vim.lsp.buf.signature_help, "Hover Signature")
          map("<c-K>", vim.lsp.buf.signature_help, "Hover Signature", "i")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          -- Diagnostic settings
          -- Diagnostic keymaps
          map("]e", function()
            vim.diagnostic.jump { count = 1 }
          end, "Go to next [D]iagnostic message")
          map("[e", function()
            vim.diagnostic.jump { count = -1 }
          end, "Go to previous [D]iagnostic message")
          -- 设置diagnostics 格式和标记
          vim.diagnostic.config {
            update_in_insert = true,
            virtual_text = {
              format = function(diagnostic)
                return string.format(
                  "%s%s.%s",
                  (diagnostic.source and diagnostic.source ~= vim.NIL) and ("[" .. diagnostic.source .. "] ") or "",
                  diagnostic.message,
                  (diagnostic.code and diagnostic.code ~= vim.NIL) and (" (" .. diagnostic.code .. ")") or ""
                )
              end,
            },
            signs = {
              text = {
                [vim.diagnostic.severity.ERROR] = "",
                [vim.diagnostic.severity.WARN] = "",
                [vim.diagnostic.severity.INFO] = "",
                [vim.diagnostic.severity.HINT] = "",
              },
            },
          }
          --
          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
    end,
  },
  -- Generic lsp server that maximizes the use of neovim's lsp capabilities
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim", "mason-org/mason.nvim" },
    config = function()
      local null_ls = require "null-ls"
      local helpers = require "null-ls.helpers"
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      null_ls.setup {
        update_in_insert = true,
        debounce = 150,
        -- register sources
        sources = {
          -- formatters
          -- lua
          null_ls.builtins.formatting.stylua,
          -- c,cpp
          null_ls.builtins.formatting.clang_format.with {
            extra_args = function()
              -- clang-format global config
              local styles = vim.json.encode {
                BasedOnStyle = "LLVM",
                IndentPPDirectives = "AfterHash",
                IndentWidth = 4,
                AllowShortBlocksOnASingleLine = true,
                AllowShortCaseLabelsOnASingleLine = true,
                -- AllowShortIfStatementsOnASingleLine = true,
                AllowShortFunctionsOnASingleLine = "All",
                AlignAfterOpenBracket = "Align",
                BreakBeforeBraces = "Custom",
                BraceWrapping = {
                  AfterClass = true,
                  AfterControlStatement = true,
                  AfterEnum = true,
                  AfterFunction = true,
                  AfterNamespace = true,
                  AfterStruct = true,
                  AfterUnion = true,
                  AfterExternBlock = true,
                  SplitEmptyFunction = false,
                  SplitEmptyRecord = false,
                  SplitEmptyNamespace = false,
                },
              }
              styles = styles:gsub('"', ""):gsub(":", ": ")
              return {
                -- use .clang-format file
                -- "-style=file",
                -- use command line arguments
                "-style=" .. styles,
              }
            end,
          },
          -- python
          null_ls.builtins.formatting.black,
          -- javascript,typescript,javascriptreact,typescriptreact,html,css,scss,sass,less,json,jsonc,json5
          null_ls.builtins.formatting.prettier.with {
            filetypes = {
              "javascript",
              "typescript",
              "javascriptreact",
              "typescriptreact",
              "html",
              "css",
              "scss",
              "sass",
              "less",
              "json",
              "jsonc",
              "json5",
              "markdown",
            },
          },
          -- sh, bash
          null_ls.builtins.formatting.shfmt.with { filetypes = { "sh", "bash", "zsh" } },
          -- sql
          null_ls.builtins.formatting.sql_formatter.with {
            extra_args = function()
              return {
                "-c",
                vim.json.encode {
                  language = "mysql",
                  tabWidth = 2,
                  keywordCase = "upper",
                  dataTypeCase = "upper",
                  functionCase = "upper",
                  linesBetweenQueries = 2,
                  paramTypes = { named = { ":" } },
                },
              }
            end,
          },
          -- yaml
          null_ls.builtins.formatting.yamlfmt,
          -- markdown
          -- null_ls.builtins.formatting.mdformat,
          -- java
          null_ls.builtins.formatting.google_java_format,
          -- xml(manual register)
          {
            name = "xmlformatter",
            method = null_ls.methods.FORMATTING,
            filetypes = { "xml" },
            generator = null_ls.formatter {
              command = "xmlformat",
              args = { "-" },
              to_stdin = true,
            },
          },
          -- linters
          -- lua
          null_ls.builtins.diagnostics.selene.with {
            condition = function(utils)
              return utils.root_has_file "selene.toml"
            end,
          },
          -- python
          null_ls.builtins.diagnostics.mypy.with {
            extra_args = function(_)
              return { "--python-executable", vim.b.python_bin }
            end,
          },
          -- html
          {
            name = "htmlhint",
            method = null_ls.methods.DIAGNOSTICS,
            filetypes = { "html" },
            generator = null_ls.generator {
              command = "htmlhint",
              args = {
                -- "global config"
                "--rules",
                "doctype-first,\
                attr-lowercase,attr-no-duplication,attr-no-unnecessary-whitespace,attr-sorted,\
                attr-unsafe-chars,attr-value-double-quotes,attr-value-no-duplication,\
                tag-no-obsolete,tag-pair,tagname-lowercase,tagname-specialchars,\
                id-class-ad-disabled,id-unique,id-class-value=dash",
                "-f",
                "json",
                "$FILENAME",
              },
              to_stdin = false,
              -- htmlhint did't supports stdin
              to_temp_file = true,
              check_exit_code = function(code)
                return code <= 1
              end,
              format = "raw",
              on_output = function(params, done)
                -- Self-parsing to handle configuration file parsing errors
                local status, response = pcall(vim.json.decode, params.output)
                if status then
                  if #response > 0 then
                    params.output = response[1].messages -- lint single file
                    for _, message in ipairs(params.output) do
                      message.rule_id = message.rule.id
                      message.rule_link = message.rule.link
                    end
                    local h = helpers.diagnostics.from_json {
                      attributes = {
                        row = "line",
                        code = "rule_id",
                        severity = "type",
                      },
                    }
                    done(h(params))
                  else
                    -- no diagnostics
                    --WARN: Cannot be omitted, otherwise the diagnostics will not be refreshed.
                    done()
                  end
                else
                  -- handle configuration file parsing errors
                  local error = vim.trim(params.output):match "[%w%s.,:/]+"
                  vim.notify("htmlhint: " .. error, vim.log.levels.WARN)
                  done()
                end
              end,
            },
          },
          -- css,scss,sass,less
          null_ls.builtins.diagnostics.stylelint.with {
            condition = function(utils)
              return utils.root_has_file {
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
              }
            end,
          },
          -- eslint_d is replaced by eslint-lsp
          -- shellcheck is called by bashls
          -- dockerfile
          null_ls.builtins.diagnostics.hadolint,
          -- sql
          null_ls.builtins.diagnostics.sqlfluff.with {
            condition = function(utils)
              return utils.root_has_file { ".sqlfluff" }
            end,
          },
          -- yaml
          null_ls.builtins.diagnostics.yamllint.with {
            condition = function(utils)
              return utils.root_has_file { ".yamllint", ".yamllint.yaml", ".yamllint.yml" }
            end,
          },
          -- hover
          {
            name = "dbee_hover",
            method = null_ls.methods.HOVER,
            filetypes = { "dbee" },
            generator = {
              fn = function(params, done)
                local status, _ = pcall(require, "dbee")
                if status then
                  local json =
                    require("lib.dbee").get_selected_row_in_json(params.bufnr, params.lsp_params.position.line)
                  if json then
                    json = "```json" .. json .. "```"
                    done { json }
                  else
                    done()
                  end
                else
                  done()
                end
              end,
              async = true,
            },
          },
          {
            name = "man_hover",
            method = null_ls.methods.HOVER,
            filetypes = { "man" },
            generator = {
              fn = function(_, done)
                local status, api = pcall(require, "inobit.llm.api")
                if status then
                  api.translate_in_lsp(done)
                else
                  done()
                end
              end,
              async = true,
            },
          },
          -- action
          {
            name = "dbee_action",
            method = null_ls.methods.CODE_ACTION,
            filetypes = { "dbee" },
            call_run = function()
              local status, _ = pcall(require, "dbee")
              return status
            end,
            generator = {
              fn = function(params)
                local actions = require("lib.dbee").code_actions(params.bufnr, params.range.row)
                return actions
              end,
            },
          },
        },
        on_attach = function(client, bufnr)
          if client.supports_method "textDocument/formatting" then
            vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                -- make sure the buffer buflisted option is not changed
                local buflisted = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
                vim.lsp.buf.format { async = false }
                vim.api.nvim_set_option_value("buflisted", buflisted, { buf = bufnr })
              end,
            })
          end
          -- get active sources name for lualine
          local sources = require("null-ls.sources").get_available(vim.bo.filetype)
          local formatters = {}
          local linters = {}
          for _, source in ipairs(sources) do
            local methods = vim.tbl_keys(source.methods)
            if vim.tbl_contains(methods, null_ls.methods.FORMATTING) then
              table.insert(formatters, source.name)
            end
            if vim.tbl_contains(methods, null_ls.methods.DIAGNOSTICS) then
              table.insert(linters, source.name)
            end
          end
          vim.b.formatters = formatters
          vim.b.linters = linters
        end,
      }
    end,
  },
}
