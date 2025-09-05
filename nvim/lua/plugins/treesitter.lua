return { -- Highlight, edit, and navigate code
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufWritePost", "BufNewFile", "VeryLazy" },
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "windwp/nvim-ts-autotag",
  },
  opts = {
    ensure_installed = {
      "bash",
      "cpp",
      "css",
      "diff",
      "html",
      "javascript",
      "json",
      "jsonc",
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
      "latex", -- need npm install -g tree-sitter-cli
      "git_config",
      "git_rebase",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "java",
    },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        node_incremental = "v",
        node_decremental = "<leader>v",
      },
    },
    textobjects = {
      select = {
        enable = true,
        -- Automatically jump forward to textobj, similar to targets.vim
        lookahead = true,
        keymaps = {
          -- You can use the capture groups defined in textobjects.scm
          ["aa"] = {
            query = "@parameter.outer",
            desc = "Select outer part of a function parameter",
          },
          ["ia"] = {
            query = "@parameter.inner",
            desc = "Select inner part of a function parameter",
          },
          ["af"] = {
            query = "@function.outer",
            desc = "Select outer part of a function region",
          },
          ["if"] = {
            query = "@function.inner",
            desc = "Select inner part of a function region",
          },
          ["as"] = {
            query = "@class.outer",
            desc = "Select inner part of a class region",
          },
          ["is"] = {
            query = "@class.inner",
            desc = "Select inner part of a class region",
          },
          ["ac"] = {
            query = "@comment.outer",
            desc = "Select inner part of a comment region",
          },
          ["ic"] = {
            query = "@comment.inner",
            desc = "select inner part of a comment region",
          },
        },
        -- you can choose the select mode (default is charwise 'v')
        --
        -- can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * method: eg 'v' or 'o'
        -- and should return the mode ('v', 'v', or '<c-v>') or a table
        -- mapping query_strings to modes.
        selection_modes = {
          ["@parameter.outer"] = "v", -- charwise
          ["@function.outer"] = "v", -- linewise
          ["@class.outer"] = "<c-v>", -- blockwise
        },
        -- If you set this to `true` (default is `false`) then any textobject is
        -- extended to include preceding or succeeding whitespace. Succeeding
        -- whitespace has priority in order to act similarly to eg the built-in
        -- `ap`.
        --
        -- Can also be a function which gets passed a table with the keys
        -- * query_string: eg '@function.inner'
        -- * selection_mode: eg 'v'
        -- and should return true or false
        include_surrounding_whitespace = false,
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { ["]f"] = "@function.outer", ["]s"] = "@class.outer", ["]a"] = "@parameter.inner" },
        goto_next_end = { ["]F"] = "@function.outer", ["]S"] = "@class.outer", ["]A"] = "@parameter.inner" },
        goto_previous_start = { ["[f"] = "@function.outer", ["[s"] = "@class.outer", ["[a"] = "@parameter.inner" },
        goto_previous_end = { ["[F"] = "@function.outer", ["[S"] = "@class.outer", ["[A"] = "@parameter.inner" },
      },
    },
    autotag = {
      enable = true,
    },
  },
  config = function(_, opts)
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    ---@diagnostic disable-next-line: missing-fields
    require("nvim-treesitter.configs").setup(opts)
  end,
}
