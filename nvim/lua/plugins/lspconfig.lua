return {
  {
    -- 快速配置lsp，虽然可以通过内置client api来手动配置,比如vim.lsp.start_client(...)
    -- 但是较麻烦,lspconfig可以快速进行配置,甚至一键默认配置,实际上就是api的重新封装,并提供了常用Lsp server的默认配置
    -- 主要功能包括启动对应的lsp server,并将相关配置传递过去,比如client的能力，lsp server本身支持的setting等等
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    dependencies = {
      -- install LSPs and related tools to stdpath for neovim
      { "williamboman/mason.nvim", version = "^1.10.0" },
      -- 这个扩展可以快速调用lspconfig来配置lsp,相当于mason和lspconfig的桥梁
      "williamboman/mason-lspconfig.nvim",
      -- 用来安装mason packages,虽然lspconfig也能auto install,但是只能install lsp server
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      -- 显示进度条,通知等
      { "j-hui/fidget.nvim", opts = {} },
      -- signatures reinforce
      {
        "ray-x/lsp_signature.nvim",
      },
    },
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
          map("]e", vim.diagnostic.goto_next, "Go to next [D]iagnostic message")
          map("[e", vim.diagnostic.goto_prev, "Go to previous [D]iagnostic message")
          -- 设置diagnostics 格式和标记
          vim.diagnostic.config {
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
          }
          vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError" })
          vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn" })
          vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo" })
          vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint" })
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
      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP Specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      -- 获取默认能力，然后进行扩展,因为客户端并没有实现所有的lsp规范
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- plugin nvim-ufo: Neovim hasn't added foldingRange to default capabilities, users must add it manually
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
      -- 这里扩展了一个cmp_nvim_lsp的能力,告诉lsp server,当前客户端支持这个能力(实现了某些接口),这样服务端响应时就会携带对应的信息了,服务端是根据客户端的能力来响应的
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local servers = {
        lua_ls = require "lsp.lua_ls",
        pyright = require "lsp.pyright",
        -- tsserver rename to ts_ls
        ts_ls = require "lsp.tsserver",
        html = require "lsp.htmlls",
        cssls = require "lsp.cssls",
        jsonls = require "lsp.jsonls",
        bashls = require "lsp.bashls",
        dockerls = require "lsp.dockerls",
        sqlls = require "lsp.sqlls",
        yamlls = require "lsp.yamlls",
        docker_compose_language_service = require "lsp.docker_compose_language_service",
        clangd = require "lsp.clangd",
        emmet_ls = require "lsp.emmetls",
        marksman = {},
      }
      require("mason").setup()
      -- install lsp server
      local ensure_installed = vim.tbl_keys(servers or {})
      -- install debugger adapter
      vim.list_extend(ensure_installed, { "codelldb" })
      -- install formatter
      vim.list_extend(ensure_installed, {
        "stylua", -- lua formatter
        "clang-format", -- c cpp formatter
        "black", -- python formatter
        "isort", -- python formatter
        "prettier", -- html,css,js,ts,json formatter
        "shfmt", -- shell formatter
        "xmlformatter", -- xml formatter
        "sql-formatter", --sql formatter
        "yamlfmt", -- yaml formatter
      })
      -- install linter
      vim.list_extend(ensure_installed, {
        "ruff", -- python linter
        "eslint_d", -- js,ts linter
        "htmlhint", -- html linter
        "stylelint", -- css,scss,sass,less linter
        "jsonlint", -- json linter
        "shellcheck", -- shell linter
        "hadolint", -- dockerfile linter
        "sqlfluff", -- sql linter
        "yamllint", -- yaml linter
      })
      require("mason-tool-installer").setup {
        ensure_installed = ensure_installed,
      }
      require("mason-lspconfig").setup {
        ensure_installed = {},
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            -- This handles overriding only values explicitly passed
            -- by the server configuration above. Useful when disabling
            -- certain features of an LSP (for example, turning off formatting for tsserver)
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            -- enable signature
            server.on_attach = function(_, bufnr)
              require("lsp_signature").on_attach({
                hint_enable = false,
                handler_opts = { border = "none" },
              }, bufnr)
            end
            -- setup lsp server
            require("lspconfig")[server_name].setup(server)
          end,
        },
      }
    end,
  },
}
