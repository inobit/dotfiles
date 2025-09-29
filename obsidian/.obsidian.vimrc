" as leader
unmap <Space>

" base keymap
nmap ' `

imap <C-j> <CR>
" <Right> is not working
imap <C-l> <Esc>la
imap <C-h> <BS>
inoremap jj <Esc>

exmap linemoveup obcommand editor:swap-line-up
nmap <A-k> :linemoveup<CR>
exmap linemovedown obcommand editor:swap-line-down
nmap <A-j> :linemovedown<CR>


nnoremap <Space>nh :nohlsearch<CR>

" Have j and k navigate visual lines rather than logical ones
nmap j gj
nmap k gk

" Yank to system clipboard
set clipboard=unnamed

" command like vim
exmap enew obcommand file-explorer:new-file
exmap w obcommand editor:save-file
exmap q obcommand workspace:close-tab-group
exmap rm obcommand app:delete-file
exmap qa obcommand workspace:close-window
exmap split obcommand workspace:split-horizontal
exmap sp obcommand workspace:split-horizontal
exmap vsplit obcommand workspace:split-vertical
exmap vs obcommand workspace:split-vertical


" Go back and forward with Ctrl+O and Ctrl+I
" (make sure to remove default Obsidian shortcuts for these to work)
exmap back obcommand app:go-back
nmap <C-o> :back<CR>
exmap forward obcommand app:go-forward
nmap <C-i> :forward<CR>

" fold
exmap togglefold obcommand editor:toggle-fold
nmap zo :togglefold<CR>
nmap zc :togglefold<CR>
nmap za :togglefold<CR>

exmap foldless obcommand editor:fold-less
nmap zr :foldless<CR>

exmap foldmore obcommand editor:fold-more
nmap zm :foldmore<CR>

exmap unfoldall obcommand editor:unfold-all
nmap zR :unfoldall<CR>

exmap foldall obcommand editor:fold-all
nmap zM :foldall<CR>


" surround
exmap surround_wiki surround [[ ]]
exmap surround_double_quotes surround " "
exmap surround_single_quotes surround ' '
exmap surround_backticks surround ` `
exmap surround_brackets surround ( )
exmap surround_square_brackets surround [ ]
exmap surround_curly_brackets surround { }
exmap surround_star surround * *

nunmap S
vunmap S
map S" :surround_double_quotes<CR>
map S' :surround_single_quotes<CR>
map S` :surround_backticks<CR>
map Sb :surround_brackets<CR>
map S[ :surround_square_brackets<CR>
map S] :surround_square_brackets<CR>
map SB :surround_curly_brackets<CR>
map S* :surround_star<CR>

" tab control
exmap tabnext obcommand workspace:next-tab
nmap <Space>l :tabnext<CR>
exmap tabprev obcommand workspace:previous-tab
nmap <Space>h :tabprev<CR>
exmap tabclose obcommand workspace:close
nmap <Space>bb :tabclose<CR>
exmap tabcloseothers obcommand workspace:close-others
nmap <Space>bo :tabcloseothers<CR>

exmap tabhistory obcommand app:go-back
nmap [b :tabhistory<CR>
exmap tabforward obcommand app:go-forward
nmap ]b :tabforward<CR>

" link
exmap gotolink obcommand editor:follow-link
nmap gd :gotolink<CR>

exmap gotolinkinnew obcommand editor:open-link-in-new-leaf
nmap gD :gotolinkinnew<CR>

" search
exmap searchglobal obcommand global-search:open
nmap <Space>sg :searchglobal<CR>

exmap search obcommand switcher:open
nmap <Space>sf :search<CR>

exmap searchhere obcommand editor:open-search
nmap <Space>ss :searchhere<CR>

exmap searchandreplacehere obcommand editor:open-search-replace
nmap <Space>sx :searchandreplacehere<CR>


" sidebar
" outline(symbol),tags,links
exmap togglerightsidebar obcommand app:toggle-right-sidebar
nmap <Space>xs :togglerightsidebar<CR>
" explorer,bookmarks,search
exmap toggleleftsidebar obcommand app:toggle-left-sidebar
nmap <Space>et :toggleleftsidebar<CR>

exmap filetreefocus obcommand file-explorer:open
nmap <Space>ef :filetreefocus<CR>

exmap bookmarksfocus obcommand bookmarks:open
nmap <Space>mf :bookmarksfocus<CR>

exmap blacklinksfocus obcommand backlink:open
nmap <Space>nf :blacklinksfocus<CR>

exmap outgoinglinksfocus obcommand outgoing-links:open
nmap <Space>Nf :outgoinglinksfocus<CR>

exmap tagfocus obcommand tag-pane:open
nmap <Space>tf :tagfocus<CR>

exmap outlinefocus obcommand outline:open
nmap <Space>xf :outlinefocus<CR>


" action
exmap contextMenu obcommand editor:context-menu
nmap ga :contextMenu<CR>

" move in split windows
exmap focusright obcommand editor:focus-right
nmap <C-l> :focusright<CR>

exmap focusleft obcommand editor:focus-left
nmap <C-h> :focusleft<CR>

exmap focustop obcommand editor:focus-top
nmap <C-k> :focustop<CR>

exmap focusbottom obcommand editor:focus-bottom
nmap <C-j> :focusbottom<CR>

" other
exmap relaod obcommand app:reload
nmap <Space>R :relaod<CR>

exmap renametitle obcommand workspace:edit-file-title
nmap <Space>rf :renametitle<CR>
