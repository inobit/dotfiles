return { -- Fuzzy Finder (files, lsp, etc)
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  branch = "0.1.x",
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
    -- Useful for getting pretty icons, but requires a Nerd Font.
    { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
  },
  config = function()
    -- Telescope is a fuzzy finder that comes with a lot of different things that
    -- it can fuzzy find! It's more than just a "file finder", it can search
    -- many different aspects of Neovim, your workspace, LSP, and more!
    --
    -- The easiest way to use telescope, is to start by doing something like:
    --  :Telescope help_tags
    --
    -- After running this command, a window will open up and you're able to
    -- type in the prompt window. You'll see a list of help_tags options and
    -- a corresponding preview of the help.
    --
    -- Two important keymaps to use while in telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!
    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    local actions = require "telescope.actions"
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
            ["<space>"] = actions.toggle_selection,
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
      },
    }
    -- Enable telescope extensions, if they are installed
    pcall(require("telescope").load_extension, "fzf")
    -- telescope 接管ui-select,下拉选项
    pcall(require("telescope").load_extension, "ui-select")
    -- See `:help telescope.builtin`
    -- stylua: ignore start
    local builtin = require "telescope.builtin"
    vim.keymap.set("n", "<leader>su", builtin.resume, { desc = "[S]earch [R]esume" })
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
    vim.keymap.set("n", "<leader>se", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
    vim.keymap.set("n", "<leader>sf", function()
      local opts = { hidden = true }
      local cmd = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
      if vim.v.shell_error == 0 then
        opts.cwd = cmd
      end
      builtin.find_files(opts)
    end, { desc = "[S]earch [F]iles" })
    vim.keymap.set("n", "<leader>sr", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[S] Find existing buffers" })
    vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
    vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set("n", "<leader>ss", function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = "[s] Fuzzily search in current buffer" })
    -- Also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set("n", "<leader>s/", function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      }
    end, { desc = "[S]earch [/] in Open Files" })
    -- Shortcut for searching your neovim configuration files
    vim.keymap.set("n", "<leader>sc", function()
      builtin.find_files { cwd = vim.fn.stdpath "config", prompt_title = "Dotfiles " }
    end, { desc = "[S]earch [N]eovim files" })
    -- stylua: ignore end
  end,
}
