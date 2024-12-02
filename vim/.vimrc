let mapleader=" "
let maplocalleader=" "

set encoding=utf-8

" optionally enable 24-bit colour
set termguicolors

set cmdheight=1

" :h hidden 允许隐藏buffer(toggleterm plugin)
set hidden

" Set highlight on search, but clear on pressing <Esc> in normal mode
set hlsearch

set number
set relativenumber
set mouse=a
" 系统剪切板，ssh远程的需要配置x-client和x-server
set clipboard=unnamedplus

" 换行后重复之前的缩进
set breakindent

" Save undo history
set undofile

" Case-insensitive searching UNLESS \C or capital in search
set ignorecase
set smartcase

" 写入swap等待时间，避免没有及时保存
set updatetime=250
" 设置按键间隔
set timeoutlen=300

" 垂直分割在右边，水平分割在下面
set splitright
set splitbelow

" Show which line your cursor is on
set cursorline
hi CursorLine cterm=None ctermbg=242 guibg=Grey20
hi CursorLineNr cterm=None ctermbg=242 guibg=Grey20

" tab使用空格
set expandtab
" 缩进2字符
set shiftwidth=2
" 制表符的显示长度
set tabstop=2
" 插入模式下tab插入的长度，如果和tabstop不同，则会使用制表符和空格混合来达成效果
" 比如sts=5 ts=2，insert时一次tab会显示为2个制表符和1个空格
set softtabstop=2
" Modes
"   normal_mode="n",
"   visual_mode="v",
"   select_mode="s",
"   visual_block_mode="x",
"   term_mode="t",
"   command_mode="c"
" key map
inoremap jj <Esc>
" save key map
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
command! W :execute ':silent w !sudo tee % >/dev/null' | edit!

" new file
nnoremap <leader>af :enew<CR>

" use 0# register
nnoremap <leader>p "0p
nnoremap <leader>P "0P

" jump
" ‘a --> `a
nnoremap ' `

" move
nnoremap <S-Up> :m-2<CR>==
nnoremap <S-Down> :m+<CR>==
" :h <Cmd> cmd没有改变mode，导致无法触发写入<,>寄存器，所以需要使用:进入cmd模式(正常都应该使用cmd,效率更高)
xnoremap <S-Up> :<C-u>'<,'>m '<-2<CR>gv=gv
xnoremap <S-Down> :<C-u>'<,'>m '>+1<CR>gv=gv
nnoremap <expr> j v:count > 1 ? "j" : "gj"
nnoremap <expr> k v:count > 1 ? "k" : "gk"

" :noh
nnoremap <leader>nh :nohlsearch<CR>

" 退出t模式
tnoremap <Esc><Esc> <C-\\><C-n>
tnoremap jj <C-\\><C-n>

"  Use CTRL+<hjkl> to switch between windows
"  See `:help wincmd` for a list of all window commands
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" 分屏
nnoremap <leader>sp <C-w>s
nnoremap <leader>vp <C-w>v

" resize
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

nnoremap <leader>at :tabnew<CR>
nnoremap ]t :tabnext<CR>
nnoremap [t :tabprevious<CR>

nnoremap <leader>l :bnext<CR>
nnoremap <leader>h :bprevious<CR>

" Stay in indent mode
vnoremap < <gv
vnoremap > >gv

inoremap <C-l> <Right>

" cmd mode move cursor
cnoremap <C-a> <Home>
cnoremap <C-f> <Right>
cnoremap <C-b> <Left>
cnoremap <A-b> <S-Left>
cnoremap <A-f> <S-Right>

" cmdline下粘贴,使用系统clip
cnoremap <C-q> <C-R>*

" bufferline
set laststatus=2
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l\ \ Column:\ %c
" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction


" plugin
colorscheme molokai
