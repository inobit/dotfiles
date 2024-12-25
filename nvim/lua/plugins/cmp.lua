return { -- Autocompletion
  -- Autocompletion的引擎，本身不提供source(候选项),需要其他扩展来提供
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    {
      "L3MON4D3/LuaSnip",
      build = (function()
        -- Build Step is needed for regex support in snippets
        -- This step is not supported in many windows environments
        -- Remove the below condition to re-enable on windows
        if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
    },
    -- 配置source
    -- LuaSnip在cmp中的适配层,让LuaSnip可以作为source提供候选项
    "saadparwaiz1/cmp_luasnip",
    -- lsp source
    "hrsh7th/cmp-nvim-lsp",
    -- 文件 source
    "hrsh7th/cmp-buffer",
    -- path source
    "hrsh7th/cmp-path",
    -- cmd line source
    "hrsh7th/cmp-cmdline",
    --包含了常见的代码片段
    "rafamadriz/friendly-snippets",
    "onsails/lspkind.nvim",
  },
  config = function()
    -- See `:help cmp`
    local cmp = require "cmp"
    local luasnip = require "luasnip"
    local lspkind = require "lspkind"
    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0
        and vim.api
            .nvim_buf_get_lines(0, line - 1, line, true)[1]
            :sub(col, col)
            :match "%s"
          == nil
    end
    -- 构建sources
    local sources = {
      { name = "nvim_lsp" },
      { name = "luasnip" },
      { name = "path" },
      { name = "buffer" },
    }
    if vim.g.ai_cmp then
      table.insert(sources, 1, { name = "codeium" })
    end
    -- 全局配置
    cmp.setup {
      -- 配置snippet,推荐必须配置,用来和snip引擎作用
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      -- :h completeopt
      completion = { completeopt = "menu,menuone,noinsert" },
      mapping = cmp.mapping.preset.insert {
        ["<C-u>"] = cmp.mapping.scroll_docs(-4), -- Up
        ["<C-d>"] = cmp.mapping.scroll_docs(4), -- Down
        ["<C-e>"] = cmp.mapping.abort(),
        -- 正常不需要,因为是自动触发
        ["<A-,>"] = cmp.mapping.complete(),
        ["<C-y>"] = {
          i = cmp.mapping.confirm { select = true },
          c = cmp.mapping.confirm { select = false },
        },
        ["<Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_next_item()
          else
            cmp.complete()
          end
        end, { "c" }),
        ["<S-Tab>"] = cmp.mapping(function()
          if cmp.visible() then
            cmp.select_prev_item()
          else
            cmp.complete()
          end
        end, { "c" }),
        ["<C-n>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
          -- that way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-p>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      },
      sources = sources,
      ---@diagnostic disable-next-line: missing-fields
      formatting = {
        format = lspkind.cmp_format {
          mode = "symbol", -- show only symbol annotations
          maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
          -- can also be a function to dynamically calculate max width such as
          -- maxwidth = function() return math.floor(0.45 * vim.o.columns) end,
          ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
          symbol_map = { Codeium = "" },
          show_labelDetails = true, -- show labelDetails in menu. Disabled by default

          -- The function below will be called before any actual modifications from lspkind
          -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
          before = function(entry, vim_item)
            vim_item.menu = "[" .. string.upper(entry.source.name) .. "]"
            return vim_item
          end,
        },
      },
    }
    -- 针对类别单独配置,比如cmdline,filetype,buffer
    -- :h getcmdtype()
    -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
    -- preset.cmdline修改了C-n,C-p,不符合使用习惯,造成无法使用历史命令
    cmp.setup.cmdline({ "/", "?" }, {
      -- completion = { completeopt = "menu,menuone,noinsert,noselect" },
      -- mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = "buffer" },
      },
    })
    -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
    cmp.setup.cmdline(":", {
      -- completion = { completeopt = "menu,menuone,noinsert,noselect" },
      -- mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        { name = "cmdline", option = { ignore_cmds = { "Man" } } },
      }),
    })
    -- 针对md help文件只使用path buffer
    cmp.setup.filetype({ "markdown", "help" }, {
      sources = {
        { name = "path" },
        { name = "buffer" },
      },
      window = {
        documentation = cmp.config.disable,
      },
    })
    -- 加载friendly-snippets
    require("luasnip.loaders.from_vscode").lazy_load()
  end,
}
