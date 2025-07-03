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

syntax on

" plugin
colorscheme molokai


" bufferline settings

" Define color variables
let g:StslineColorGreen  = "#2BBB4F"
let g:StslineColorBlue   = "#4799EB"
let g:StslineColorViolet = "#986FEC"
let g:StslineColorYellow = "#D7A542"
let g:StslineColorOrange = "#EB754D"
 
let g:StslineColorLight  = "#C0C0C0"
let g:StslineColorDark   = "#080808"
let g:StslineColorDark1  = "#181818"
let g:StslineColorDark2  = "#202020"
let g:StslineColorDark3  = "#303030"
 
 
" Define colors
let g:StslineBackColor   = g:StslineColorDark2
let g:StslineOnBackColor = g:StslineColorLight
"let g:StslinePriColor   = g:StslineColorGreen
let g:StslineOnPriColor  = g:StslineColorDark
let g:StslineSecColor    = g:StslineColorDark3
let g:StslineOnSecColor  = g:StslineColorLight
 
 
" Create highlight groups
execute 'highlight StslineSecColorFG guifg=' . g:StslineSecColor   ' guibg=' . g:StslineBackColor
execute 'highlight StslineSecColorBG guifg=' . g:StslineColorLight ' guibg=' . g:StslineSecColor
execute 'highlight StslineBackColorBG guifg=' . g:StslineColorLight ' guibg=' . g:StslineBackColor
execute 'highlight StslineBackColorFGSecColorBG guifg=' . g:StslineBackColor ' guibg=' . g:StslineSecColor
execute 'highlight StslineSecColorFGBackColorBG guifg=' . g:StslineSecColor ' guibg=' . g:StslineBackColor
execute 'highlight StslineModColorFG guifg=' . g:StslineColorYellow ' guibg=' . g:StslineBackColor
 
 
 
" Statusline
 
" Enable statusline
set laststatus=2
 
" Disable showmode - i.e. Don't show mode like --INSERT-- in current statusline.
set noshowmode
 
" Enable GUI colors for terminals (Some terminals may not support this, so you'll have to *manually* set color pallet for tui colors. Lie tuibg=255, tuifg=120, etc.).
set termguicolors
 
 
 
" Understand statusline elements
 
" %{StslineMode()}  = Output of a function
" %#StslinePriColorBG# = Highlight group
" %F, %c, etc. are variables which contain value like - current file path, current colums, etc.
" %{&readonly?\"\ \":\"\"} = If file is readonly ? Then "Lock icon" Else : "Nothing"
" %{get(b:,'coc_git_status',b:GitBranch)}    = If b:coc_git_status efists, then it's value, else value of b:GitBranch
" &filetype, things starting with & are also like variables with info.
" \  - Is for escaping a space. \" is for escaping a double quote.
" %{&fenc!='utf-8'?\"\ \":''}   = If file encoding is NOT!= 'utf-8' ? THEN output a "Space" else : no character 
 
 
 
" Define active statusline
 
function! ActivateStatusline()
call GetFileType()
setlocal statusline=%#StslinePriColorBG#\ %{StslineMode()}%#StslineSecColorBG#%{get(b:,'coc_git_status',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGPriColorBG#%#StslinePriColorFG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslinePriColorFG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFG#%#StslineSecColorBG#%{&fenc!='utf-8'?\"\ \":''}%{&fenc!='utf-8'?&fenc:''}%{&fenc!='utf-8'?\"\ \":''}%#StslinePriColorFGSecColorBG#%#StslinePriColorBG#\ %p\%%\ %#StslinePriColorBGBold#%l%#StslinePriColorBG#/%L\ :%c\ 
endfunction
 
 
 
" Define Inactive statusline
 
function! DeactivateStatusline()
 
if !exists("b:GitBranch") || b:GitBranch == ''
setlocal statusline=%#StslineSecColorBG#\ INACTIVE\ %#StslineSecColorBG#%{get(b:,'coc_git_statusline',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGSecColorBG#%#StslineBackColorBG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslineBackColorBG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFGBackColorBG#%#StslineSecColorBG#\ %p\%%\ %l/%L\ :%c\ 
 
else
setlocal statusline=%#StslineSecColorBG#%{get(b:,'coc_git_statusline',b:GitBranch)}%{get(b:,'coc_git_blame','')}%#StslineBackColorFGSecColorBG#%#StslineBackColorBG#\ %{&readonly?\"\ \":\"\"}%F\ %#StslineModColorFG#%{&modified?\"\ \":\"\"}%=%#StslineBackColorBG#\ %{b:FiletypeIcon}%{&filetype}\ %#StslineSecColorFGBackColorBG#%#StslineSecColorBG#\ %p\%%\ %l/%L\ :%c\ 
endif
 
endfunction
 
 
 
" Get Statusline mode & also set primary color for that mode
function! StslineMode()
 
    let l:CurrentMode=mode()
 
    if l:CurrentMode==#"n"
        let g:StslinePriColor     = g:StslineColorGreen
        let b:CurrentMode = "NORMAL "
 
    elseif l:CurrentMode==#"i"
        let g:StslinePriColor     = g:StslineColorViolet
        let b:CurrentMode = "INSERT "
 
    elseif l:CurrentMode==#"c"
        let g:StslinePriColor     = g:StslineColorYellow
 
        let b:CurrentMode = "COMMAND "
 
    elseif l:CurrentMode==#"v"
        let g:StslinePriColor     = g:StslineColorBlue
        let b:CurrentMode = "VISUAL "
 
    elseif l:CurrentMode==#"V"
        let g:StslinePriColor     = g:StslineColorBlue
        let b:CurrentMode = "V-LINE "
 
    elseif l:CurrentMode==#"\<C-v>"
        let g:StslinePriColor     = g:StslineColorBlue
        let b:CurrentMode = "V-BLOCK "
 
    elseif l:CurrentMode==#"R"
        let g:StslinePriColor     = g:StslineColorViolet
        let b:CurrentMode = "REPLACE "
 
    elseif l:CurrentMode==#"s"
        let g:StslinePriColor     = g:StslineColorBlue
        let b:CurrentMode = "SELECT "
 
    elseif l:CurrentMode==#"t"
        let g:StslinePriColor     =g:StslineColorYellow
        let b:CurrentMode = "TERM "
 
    elseif l:CurrentMode==#"!"
        let g:StslinePriColor     = g:StslineColorYellow
        let b:CurrentMode = "SHELL "
 
    endif
 
 
    call UpdateStslineColors()
    
    return b:CurrentMode
 
endfunction
 
 
 
" Update colors. Recreate highlight groups with new Primary color value.
function! UpdateStslineColors()
 
execute 'highlight StslinePriColorBG           guifg=' . g:StslineOnPriColor ' guibg=' . g:StslinePriColor
execute 'highlight StslinePriColorBGBold       guifg=' . g:StslineOnPriColor ' guibg=' . g:StslinePriColor ' gui=bold'
execute 'highlight StslinePriColorFG           guifg=' . g:StslinePriColor   ' guibg=' . g:StslineBackColor
execute 'highlight StslinePriColorFGSecColorBG guifg=' . g:StslinePriColor   ' guibg=' . g:StslineSecColor
execute 'highlight StslineSecColorFGPriColorBG guifg=' . g:StslineSecColor   ' guibg=' . g:StslinePriColor
 
if !exists("b:GitBranch") || b:GitBranch == ''
execute 'highlight StslineBackColorFGPriColorBG guifg=' . g:StslineBackColor ' guibg=' . g:StslinePriColor
endif
 
endfunction
 
 
 
" Get git branch name
 
function! GetGitBranch()
let b:GitBranch=""
try
    let l:dir=expand('%:p:h')
    let l:gitrevparse = system("git -C ".l:dir." rev-parse --abbrev-ref HEAD")
    if !v:shell_error
        let b:GitBranch="   ".substitute(l:gitrevparse, '\n', '', 'g')." "
        execute 'highlight StslineBackColorFGPriColorBG guifg=' . g:StslineBackColor ' guibg=' . g:StslineSecColor
    endif
catch
endtry
endfunction
 
 
 
" Get filetype & custom icon. Put your most used file types first for optimized performance.
function! GetFileType()
  if &filetype == 'typescript'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'typescriptreact'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'javascript'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'javascriptreact'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'html'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'css'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'scss'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'json'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'markdown'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'vim'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'sh' || &filetype == 'zsh' || &filetype == 'bash'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'python'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'java'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'c'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'cpp'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'go'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'rust'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'php'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'ruby'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'lua'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'haskell'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'dockerfile'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'yaml' || &filetype == 'yml'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'xml'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'sql'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'tex'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'txt'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'gitcommit'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'makefile'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'cmake'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'graphql'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'toml'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'fsharp'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'swift'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'kotlin'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'scala'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'elixir'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'erlang'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'puppet'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'terraform'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'groovy'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'perl'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'julia'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'clojure'
    let b:FiletypeIcon = ' '
  elseif &filetype == 'dart'
    let b:FiletypeIcon = ' '
  elseif &filetype == ''
    let b:FiletypeIcon = ''
  else
    let b:FiletypeIcon = ' '
  endif
endfunction
 
 
" Get git branch name after entering a buffer
augroup GetGitBranch
    autocmd!
    autocmd BufEnter * call GetGitBranch()
augroup END
 
 
" Set active / inactive statusline after entering, leaving buffer
augroup SetStslineline
    autocmd!
    autocmd BufEnter,WinEnter * call ActivateStatusline()
    autocmd BufLeave,WinLeave * call DeactivateStatusline()
augroup END

