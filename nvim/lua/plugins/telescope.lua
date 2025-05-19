return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  -- branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { -- If encountering errors, see telescope-fzf-native README for install instructions
      -- 该插件,用于模糊查询,前置后置匹配,反向查询等等,没有提供binary版，需要编译
      "nvim-telescope/telescope-fzf-native.nvim",
      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.
      build = "make",
      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable "make" == 1
      end,
    },
    -- telescope扩展插件,用于neovim一些内置功能可以直接调用telescope picker,比如lua vim.lsp.buf.code_action()
    -- 本质上是使用vim.ui.select to telescope
    { "nvim-telescope/telescope-ui-select.nvim" },
    { "nvim-telescope/telescope-file-browser.nvim" },
    -- Useful for getting pretty icons, but requires a Nerd Font.
    { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
  },
  config = function()
    -- Two important keymaps to use while in telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    local actions = require "telescope.actions"
    local fb_actions = require("telescope").extensions.file_browser.actions
    require("telescope").setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      defaults = {
        -- 以nomarl mode进入picker
        initial_mode = "normal",
        mappings = {
          -- i = { ['<c-enter>'] = 'to_fuzzy_refine' },
          n = {
            ["<leader>q"] = actions.close,
          },
        },
      },
      pickers = {
        buffers = {
          show_all_buffers = true,
          sort_mru = true,
          mappings = {
            n = {
              ["<leader>bb"] = actions.delete_buffer,
            },
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        },
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
        file_browser = {
          theme = "ivy",
          mappings = {
            ["n"] = {
              ["a"] = fb_actions.create,
              c = false,
              ["o"] = fb_actions.open_dir,
              ["p"] = fb_actions.goto_parent_dir,
              g = false,
              ["~"] = fb_actions.goto_home_dir,
              e = false,
              ["<C-CR>"] = fb_actions.open,
            },
          },
        },
      },
    }
    -- Enable telescope extensions, if they are installed
    pcall(require("telescope").load_extension, "fzf")
    -- telescope 接管ui-select,下拉选项
    pcall(require("telescope").load_extension, "ui-select")
    -- file_browser
    pcall(require("telescope").load_extension, "file_browser")

    -- See `:help telescope.builtin`
    -- stylua: ignore start
    local builtin = require "telescope.builtin"
    vim.keymap.set("n", "<leader>su", builtin.resume, { desc = "Telescope: Search Resume" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "Telescope: Search Help" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "Telescope: Search Keymaps" })
    vim.keymap.set("n", "<leader>se", builtin.diagnostics, { desc = "Telescope: Search Diagnostics" })
    vim.keymap.set("n", "<leader>sj", builtin.jumplist, { desc = "Telescope: Search Jumplist" })

    vim.keymap.set( "n", "<leader>fd", "<Cmd>Telescope file_browser path=%:p:h select_buffer=true<CR>",
      { desc = "Telescope: Search Files in current folder" }
    )

    vim.keymap.set("n", "<leader>ff", function()
      require("telescope").extensions.file_browser.file_browser()
    end,{desc = "Telescope: Search Files in CWD" })

    vim.keymap.set("n", "<leader>sd", function()
      builtin.find_files { hidden = true, cwd = require("telescope.utils").buffer_dir() }
    end, { desc = "telescope: search files in current folder" })

    local search_files = function(hidden)
      local opts = { hidden = hidden, no_ignore = hidden }
      -- local cmd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
      -- if vim.v.shell_error == 0 then
      --   opts.cwd = cmd
      -- end
      builtin.find_files(opts)
    end
    vim.keymap.set("n", "<leader>sf", function() search_files(false) end, {desc = "Telescope: Search Files in CWD" })
    vim.keymap.set("n", "<leader>sF", function() search_files(true) end, { desc = "Telescope: Search Files(including hidden and ignored) in CWD" })

    -- vim.keymap.set("n", "<leader>sf", builtin.find_files, {desc = "Telescope: Search Files in CWD" })

    vim.keymap.set("n", "<leader>sr", builtin.oldfiles, { desc = 'Telescope: Search Recent Files ("." for repeat)' })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Telescope: Find existing buffers" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "Telescope: Search current Word" })
    vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "Telescope: Search by Grep" })
    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set("n", "<leader>ss", function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = "Telescope: Fuzzily search in current buffer" })

    vim.keymap.set("n", "<leader>s/", function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      }
    end, { desc = "Telescope: Search [/] in Open Files" })
    -- Shortcut for searching your neovim configuration files
    vim.keymap.set("n", "<leader>sc", function()
      builtin.find_files { cwd = vim.fn.stdpath "config",no_ignore = true, prompt_title = "Dotfiles " }
    end, { desc = "Telescope: Search Neovim files" })
    -- stylua: ignore end
  end,
}
