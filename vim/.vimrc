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

function! Osc52AutoYank()
  if v:event.operator !=# 'y' && v:event.operator !=# 'd' && v:event.operator !=# 'c'
    return
  endif
  let l:text = getreg('"')
  let l:encoded = system('base64 -w0', l:text)
  let l:encoded = substitute(l:encoded, '\n$', '', '')
  call system('printf "\033]52;c;' . l:encoded . '\007" > /dev/tty')
endfunction

augroup Osc52Clipboard
  autocmd!
  autocmd TextYankPost * call Osc52AutoYank()
augroup END

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
" nnoremap <leader>q :q<CR>
command! W :execute ':silent w !sudo tee % >/dev/null' | edit!

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

" resize
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

nnoremap ]t :tabnext<CR>
nnoremap [t :tabprevious<CR>

nnoremap ]b :bnext<CR>
nnoremap [b :bprevious<CR>

" file explorer - 静默执行，不显示命令行
nnoremap <expr> - "<Cmd>Explore " . (empty(expand('%:h')) ? '.' : expand('%:h')) . "<CR>"
nnoremap ~ <Cmd>Explore ~/<CR>

" 垂直分割线样式（实线，无背景）
set fillchars+=vert:│

" Netrw Preview (Ctrl+P toggle)
let g:preview_win = -1

function! IsText(fname)
  let blob = readfile(a:fname, 'B', 4096)
  return blob->string() !~# '\%x00'
endfunction

function! PreviewClose()
  if g:preview_win > 0 && win_id2win(g:preview_win) > 0
    call win_execute(g:preview_win, 'close')
  endif
  let g:preview_win = -1
endfunction

function! PreviewUpdate()
  if g:preview_win <= 0 || win_id2win(g:preview_win) <= 0
    return
  endif

  let line = getline('.')
  if line =~# '^["$/]' || line =~# '^$' | return | endif

  let fname = substitute(line, '^\s*', '', '')
  let fname = substitute(fname, '\s\+\d.*$', '', '')
  if fname == '' | return | endif

  let path = b:netrw_curdir . '/' . fname
  let path = fnamemodify(path, ':p')

  if isdirectory(path)
    " Remove trailing slash from path to avoid double slashes
    let clean_path = substitute(path, '/$', '', '')
    let lines = ['=== Directory: ' . fname . ' ===', ''] + glob(clean_path . '/*', 0, 1)
  elseif !filereadable(path)
    let lines = ['=== Cannot read: ' . fname . ' ===']
  elseif !IsText(path)
    let lines = ['=== Binary file: ' . fname . ' ===']
  else
    let lines = readfile(path, '', 500)
    if empty(lines) | let lines = ['(empty file)'] | endif
  endif

  call win_execute(g:preview_win, '%delete _ | call setline(1, ' . string(lines) . ')')
endfunction

function! PreviewToggle()
  if g:preview_win > 0 && win_id2win(g:preview_win) > 0
    " Save cursor position before closing preview
    let save_pos = getcurpos()
    call PreviewClose()
    " Restore cursor position after closing
    call setpos('.', save_pos)
  else
    let save_pos = getcurpos()
    silent! rightbelow vnew
    let g:preview_win = win_getid()
    silent! wincmd p
    call win_execute(g:preview_win, 'setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted readonly nocursorline nocursorcolumn')
    call setpos('.', save_pos)
    call PreviewUpdate()
  endif
endfunction

augroup NetrwPreview
  autocmd!
  autocmd FileType netrw nnoremap <silent> <buffer> <C-p> <Cmd>call PreviewToggle()<CR>
  autocmd FileType netrw nnoremap <silent> <buffer> j j<Cmd>call PreviewUpdate()<CR>
  autocmd FileType netrw nnoremap <silent> <buffer> k k<Cmd>call PreviewUpdate()<CR>
  autocmd FileType netrw nnoremap <silent> <buffer> <Down> <Down><Cmd>call PreviewUpdate()<CR>
  autocmd FileType netrw nnoremap <silent> <buffer> <Up> <Up><Cmd>call PreviewUpdate()<CR>
  autocmd FileType netrw nnoremap <silent> <buffer> q <Cmd>call PreviewClose() <Bar> bd<CR>
  " netrw statusline：只显示当前目录（带颜色）
  autocmd FileType netrw setlocal statusline=%#StslineBackColorBG#\ %{getcwd()}
  autocmd BufLeave * if &filetype == 'netrw' | call PreviewClose() | endif
augroup END

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

" ============================================================
" molokai 颜色方案 (内嵌)
" Author: Tomas Restrepo <tomas@winterdom.com>
" https://github.com/tomasr/molokai
" ============================================================

if exists("g:molokai_original")
    let s:molokai_original = g:molokai_original
else
    let s:molokai_original = 0
endif

hi Boolean         guifg=#AE81FF
hi Character       guifg=#E6DB74
hi Number          guifg=#AE81FF
hi String          guifg=#E6DB74
hi Conditional     guifg=#F92672               gui=bold
hi Constant        guifg=#AE81FF               gui=bold
hi Cursor          guifg=#000000 guibg=#F8F8F0
hi iCursor         guifg=#000000 guibg=#F8F8F0
hi Debug           guifg=#BCA3A3               gui=bold
hi Define          guifg=#66D9EF
hi Delimiter       guifg=#8F8F8F
hi DiffAdd                       guibg=#13354A
hi DiffChange      guifg=#89807D guibg=#4C4745
hi DiffDelete      guifg=#960050 guibg=#1E0010
hi DiffText                      guibg=#4C4745 gui=italic,bold
hi Directory       guifg=#A6E22E               gui=bold
hi Error           guifg=#E6DB74 guibg=#1E0010
hi ErrorMsg        guifg=#F92672 guibg=#232526 gui=bold
hi Exception       guifg=#A6E22E               gui=bold
hi Float           guifg=#AE81FF
hi FoldColumn      guifg=#465457 guibg=#000000
hi Folded          guifg=#465457 guibg=#000000
hi Function        guifg=#A6E22E
hi Identifier      guifg=#FD971F
hi Ignore          guifg=#808080 guibg=bg
hi IncSearch       guifg=#C4BE89 guibg=#000000
hi Keyword         guifg=#F92672               gui=bold
hi Label           guifg=#E6DB74               gui=none
hi Macro           guifg=#C4BE89               gui=italic
hi SpecialKey      guifg=#66D9EF               gui=italic
hi MatchParen      guifg=#000000 guibg=#FD971F gui=bold
hi ModeMsg         guifg=#E6DB74
hi MoreMsg         guifg=#E6DB74
hi Operator        guifg=#F92672
hi Pmenu           guifg=#66D9EF guibg=#000000
hi PmenuSel                      guibg=#808080
hi PmenuSbar                     guibg=#080808
hi PmenuThumb      guifg=#66D9EF
hi PreCondit       guifg=#A6E22E               gui=bold
hi PreProc         guifg=#A6E22E
hi Question        guifg=#66D9EF
hi Repeat          guifg=#F92672               gui=bold
hi Search          guifg=#000000 guibg=#FFE792
hi SignColumn      guifg=#A6E22E guibg=#232526
hi SpecialChar     guifg=#F92672               gui=bold
hi SpecialComment  guifg=#7E8E91               gui=bold
hi Special         guifg=#66D9EF guibg=bg      gui=italic
if has("spell")
    hi SpellBad    guisp=#FF0000 gui=undercurl
    hi SpellCap    guisp=#7070F0 gui=undercurl
    hi SpellLocal  guisp=#70F0F0 gui=undercurl
    hi SpellRare   guisp=#FFFFFF gui=undercurl
endif
hi Statement       guifg=#F92672               gui=bold
hi StatusLine      guifg=#455354 guibg=fg
hi StatusLineNC    guifg=#808080 guibg=#080808
hi StorageClass    guifg=#FD971F               gui=italic
hi Structure       guifg=#66D9EF
hi Tag             guifg=#F92672               gui=italic
hi Title           guifg=#ef5939
hi Todo            guifg=#FFFFFF guibg=bg      gui=bold
hi Typedef         guifg=#66D9EF
hi Type            guifg=#66D9EF               gui=none
hi Underlined      guifg=#808080               gui=underline
hi VertSplit       guifg=#808080 guibg=#080808 gui=bold
hi VisualNOS                     guibg=#403D3D
hi Visual                        guibg=#403D3D
hi WarningMsg      guifg=#FFFFFF guibg=#333333 gui=bold
hi WildMenu        guifg=#66D9EF guibg=#000000
hi TabLineFill     guifg=#1B1D1E guibg=#1B1D1E
hi TabLine         guibg=#1B1D1E guifg=#808080 gui=none

if s:molokai_original == 1
   hi Normal          guifg=#F8F8F2 guibg=#272822
   hi Comment         guifg=#75715E
   hi CursorLine                    guibg=#3E3D32
   hi CursorLineNr    guifg=#FD971F               gui=none
   hi CursorColumn                  guibg=#3E3D32
   hi ColorColumn                   guibg=#3B3A32
   hi LineNr          guifg=#BCBCBC guibg=#3B3A32
   hi NonText         guifg=#75715E
   hi SpecialKey      guifg=#75715E
else
   hi Normal          guifg=#F8F8F2 guibg=#1B1D1E
   hi Comment         guifg=#7E8E91
   hi CursorLine                    guibg=#293739
   hi CursorLineNr    guifg=#FD971F               gui=none
   hi CursorColumn                  guibg=#293739
   hi ColorColumn                   guibg=#232526
   hi LineNr          guifg=#465457 guibg=#232526
   hi NonText         guifg=#465457
   hi SpecialKey      guifg=#465457
end

if &t_Co > 255
   if s:molokai_original == 1
      hi Normal                   ctermbg=234
      hi CursorLine               ctermbg=235   cterm=none
      hi CursorLineNr ctermfg=208               cterm=none
   else
      hi Normal       ctermfg=252 ctermbg=233
      hi CursorLine               ctermbg=234   cterm=none
      hi CursorLineNr ctermfg=208               cterm=none
   endif
   hi Boolean         ctermfg=135
   hi Character       ctermfg=144
   hi Number          ctermfg=135
   hi String          ctermfg=144
   hi Conditional     ctermfg=161               cterm=bold
   hi Constant        ctermfg=135               cterm=bold
   hi Cursor          ctermfg=16  ctermbg=253
   hi Debug           ctermfg=225               cterm=bold
   hi Define          ctermfg=81
   hi Delimiter       ctermfg=241
   hi DiffAdd                     ctermbg=24
   hi DiffChange      ctermfg=181 ctermbg=239
   hi DiffDelete      ctermfg=162 ctermbg=53
   hi DiffText                    ctermbg=102 cterm=bold
   hi Directory       ctermfg=118               cterm=bold
   hi Error           ctermfg=219 ctermbg=89
   hi ErrorMsg        ctermfg=199 ctermbg=16    cterm=bold
   hi Exception       ctermfg=118               cterm=bold
   hi Float           ctermfg=135
   hi FoldColumn      ctermfg=67  ctermbg=16
   hi Folded          ctermfg=67  ctermbg=16
   hi Function        ctermfg=118
   hi Identifier      ctermfg=208               cterm=none
   hi Ignore          ctermfg=244 ctermbg=232
   hi IncSearch       ctermfg=193 ctermbg=16
   hi keyword         ctermfg=161               cterm=bold
   hi Label           ctermfg=229               cterm=none
   hi Macro           ctermfg=193
   hi SpecialKey      ctermfg=81
   hi MatchParen      ctermfg=233  ctermbg=208 cterm=bold
   hi ModeMsg         ctermfg=229
   hi MoreMsg         ctermfg=229
   hi Operator        ctermfg=161
   hi Pmenu           ctermfg=81  ctermbg=16
   hi PmenuSel        ctermfg=255 ctermbg=242
   hi PmenuSbar                   ctermbg=232
   hi PmenuThumb      ctermfg=81
   hi PreCondit       ctermfg=118               cterm=bold
   hi PreProc         ctermfg=118
   hi Question        ctermfg=81
   hi Repeat          ctermfg=161               cterm=bold
   hi Search          ctermfg=0   ctermbg=222   cterm=NONE
   hi SignColumn      ctermfg=118 ctermbg=235
   hi SpecialChar     ctermfg=161               cterm=bold
   hi SpecialComment  ctermfg=245               cterm=bold
   hi Special         ctermfg=81
   if has("spell")
       hi SpellBad                ctermbg=52
       hi SpellCap                ctermbg=17
       hi SpellLocal              ctermbg=17
       hi SpellRare  ctermfg=none ctermbg=none  cterm=reverse
   endif
   hi Statement       ctermfg=161               cterm=bold
   hi StatusLine      ctermfg=238 ctermbg=253
   hi StatusLineNC    ctermfg=244 ctermbg=232
   hi StorageClass    ctermfg=208
   hi Structure       ctermfg=81
   hi Tag             ctermfg=161
   hi Title           ctermfg=166
   hi Todo            ctermfg=231 ctermbg=232   cterm=bold
   hi Typedef         ctermfg=81
   hi Type            ctermfg=81                cterm=none
   hi Underlined      ctermfg=244               cterm=underline
   hi VertSplit       ctermfg=244 ctermbg=232   cterm=bold
   hi VisualNOS                   ctermbg=238
   hi Visual                      ctermbg=235
   hi WarningMsg      ctermfg=231 ctermbg=238   cterm=bold
   hi WildMenu        ctermfg=81  ctermbg=16
   hi Comment         ctermfg=59
   hi CursorColumn                ctermbg=236
   hi ColorColumn                 ctermbg=236
   hi LineNr          ctermfg=250 ctermbg=236
   hi NonText         ctermfg=59
   hi SpecialKey      ctermfg=59
endif

set background=dark


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

