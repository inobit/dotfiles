return {
  { -- Autocompletion
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "saghen/blink.lib",
      "saghen/blink.compat",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
      "rcarriga/cmp-dap",
    },
    build = function()
      if vim.fn.has "win32" == 1 then
        local dll = vim.fn.stdpath "data" .. "/lazy/blink.cmp/lib/libblink_cmp_fuzzy.dll"
        if vim.uv.fs_stat(dll) then
          return -- prebuilt DLL already downloaded manually
        end
        require("blink.cmp").download({ match = "v*" }):pwait()
      else
        require("blink.cmp").build():pwait()
      end
    end,
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.compat",
      "sources.default",
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      snippets = { preset = "default" },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        accept = {
          auto_brackets = { enabled = true },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
              { "source_name" },
            },
            components = {
              kind_icon = {
                text = function(ctx)
                  if ctx.item.source_name == "LSP" then
                    local color_item =
                      require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                    if color_item and color_item.abbr ~= "" then
                      return color_item.abbr .. ctx.icon_gap
                    end
                  end
                  return (require("lspkind").symbol_map[ctx.kind] or "") .. ctx.icon_gap
                end,
                highlight = function(ctx)
                  if ctx.item.source_name == "LSP" then
                    local color_item =
                      require("nvim-highlight-colors").format(ctx.item.documentation, { kind = ctx.kind })
                    if color_item and color_item.abbr_hl_group then
                      return color_item.abbr_hl_group
                    end
                  end
                  return "BlinkCmpKind" .. ctx.kind
                end,
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = { enabled = true },
      },
      sources = {
        compat = { "cmp-dbee", "dap" },
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          sql = { "cmp-dbee", "buffer" },
          mysql = { "cmp-dbee", "buffer" },
          plsql = { "cmp-dbee", "buffer" },
          ["dap-repl"] = { "dap", "buffer" },
          dapui_watches = { "dap", "buffer" },
          dapui_hover = { "dap", "buffer" },
          lua = { inherit_defaults = true, "lazydev" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- show at a higher priority than lsp
          },
        },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ":"
            end,
          },
        },
      },
      keymap = {
        preset = "default",
        ["<A-,>"] = { "show", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<C-u>"] = { "scroll_signature_up", "fallback" },
        ["<C-d>"] = { "scroll_signature_down", "fallback" },
      },
    },
    config = function(_, opts)
      -- Register compat sources
      opts.sources.providers = opts.sources.providers or {}
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
      end
      -- Remove before validation
      opts.sources.compat = nil
      require("blink.cmp").setup(opts)
    end,
  },
}
