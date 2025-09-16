-- Modes
--   normal_mode = "n",
--   vmap for both "visual_mode" and "select_mode"
--   visual_mode = "v",
--   select_mode = "s", -- gh
--   xmap just for "visual_mode"
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c"
--   operator-pending_mode = "o"
--  See `:help vim.keymap.set()`
vim.keymap.set("i", "jj", "<Esc>")
-- save key map
vim.keymap.set("n", "<leader>w", "<Cmd>w<CR>", { desc = ":w" })
-- vim.keymap.set("n", "<leader>q", "<Cmd>q<CR>", { desc = ":q" })

-- use 0# register
vim.keymap.set("n", "<leader>p", '"0p')
vim.keymap.set("n", "<leader>P", '"0P')

-- jump
-- ‘a --> `a
vim.keymap.set("n", "'", "`")
-- last change
vim.keymap.set("n", "g.", "`Z")

-- move
vim.keymap.set("n", "<A-k>", "<Cmd>m-2<CR>==")
vim.keymap.set("n", "<A-j>", "<Cmd>m+<CR>==")
-- :h <Cmd> cmd没有改变mode，导致无法触发写入<,>寄存器，所以需要使用:进入cmd模式(正常都应该使用cmd,效率更高)
vim.keymap.set("x", "<A-j>", ":<C-u>'<,'>m '>+1<CR>gv=gv")
vim.keymap.set("x", "<A-k>", ":<C-u>'<,'>m '<-2<CR>gv=gv")

vim.keymap.set("n", "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true })
vim.keymap.set("n", "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true })

-- :noh
vim.keymap.set("n", "<leader>nh", "<Cmd>nohlsearch<CR>")

-- delete empty line
-- vim.keymap.set("n", "<leader>dL", ":<C-u>g/^$/d<CR> <bar> :nohlsearch<CR>")
vim.keymap.set("n", "<leader>dL", function()
  vim.cmd [[g/^$/d]]
  vim.cmd.nohlsearch()
end)

-- 退出t模式
-- stylua: ignore start
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "jj", "<C-\\><C-n>", { desc = "Exit terminal mode" })

--  Use CTRL+<hjkl> to switch between windows
--  See `:help wincmd` for a list of all window commands
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move focus to the upper window" })
-- stylua: ignore end

-- resize
vim.keymap.set("n", "<C-Up>", "<Cmd>resize +2<CR>")
vim.keymap.set("n", "<C-Down>", "<Cmd>resize -2<CR>")
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -2<CR>")
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +2<CR>")

vim.keymap.set("n", "]T", "<Cmd>tabnext<CR>", { desc = "next tab" })
vim.keymap.set("n", "[T", "<Cmd>tabprevious<CR>", { desc = "previous tab" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set("i", "<C-l>", "<Right>")

-- cmd mode move cursor
vim.keymap.set("c", "<C-a>", "<Home>")
vim.keymap.set("c", "<C-f>", "<Right>")
vim.keymap.set("c", "<C-b>", "<Left>")
vim.keymap.set("c", "<A-b>", "<S-Left>")
vim.keymap.set("c", "<A-f>", "<S-Right>")
-- register, paste under cmdline, use system clip
vim.keymap.set("c", "<C-q>", "<C-R>+")

-- execute
vim.keymap.set("n", "<leader><leader>x", "<Cmd>source %<CR>", { desc = "execute current file" })
vim.keymap.set("n", "<leader><leader>X", "<Cmd>source $MYVIMRC<CR>", { desc = "execute $MYVIMRC file" })
vim.keymap.set("n", "<leader>X", ":.lua<CR>", { desc = "execute current lua line" })
vim.keymap.set("v", "<leader>X", ":lua<CR>", { desc = "execute selected lua block" })
vim.keymap.set("n", "<leader><leader>t", "<Cmd>PlenaryBustedFile %<CR>", { desc = "run test" })

-- show messages
vim.keymap.set("n", "<leader><leader>m", function()
  local lines = vim.split(vim.fn.execute("messages", "silent"), "\n")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
end, { desc = "show messages in current cursor" })

if vim.env.TMUX then
  vim.keymap.set("n", "<C-l>", function()
    require("lib.run").run "clear"
  end, { desc = "clear print", silent = true, noremap = true })
end
