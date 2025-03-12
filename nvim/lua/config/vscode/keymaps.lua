---@diagnostic disable: unused-local
-- key map
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, noremap = true, silent = true })
end
local vscode = require "vscode-neovim"

-- stylua: ignore start

-- save
map("n", "<leader>w", function() vscode.action "workbench.action.files.save" end, "vscode: save file")

-- quit
map("n", "<leader>q", function() vscode.action "workbench.action.closeActiveEditor" end, "vscode: close editor")

-- use 0# register
map("n", "<leader>p", '"0p',"vscode: \"0 p")
map("n", "<leader>P", '"0P',"vscode: \"0 P")

-- last edit
map("n", "g.", function() vscode.action "workbench.action.navigateToLastEditLocation" end, "vscode: go to last edit location")

-- jump
map("n", "<C-o>", function() vscode.action "workbench.action.navigateBack" end, "vscode: go back")
map("n", "<C-i>", function() vscode.action "workbench.action.navigateForward" end, "vscode: go forward")
-- ‘a --> `a
map("n", "'", "`","vscode: mark")

-- no hightlight
map("n", "<leader>nh", "<Cmd>nohlsearch<CR>","vscode: cancel hightlight")

-- indent
map("v", "<", "<gv","vscode: left indent")
map("v", ">", ">gv","vscode: right indent")

-- wrap lines j k
local function moveCursor(direction)
    if (vim.v.count == 0 and vim.fn.reg_recording() == '' and vim.fn.reg_executing() == '') then
        return ('g' .. direction)
    else
        return direction
    end
end
vim.keymap.set("n", "k", function () return moveCursor("k") end, { expr = true, remap=true, desc = "vscode: wrap lines k" })
vim.keymap.set("n", "j", function () return moveCursor("j") end, { expr = true, remap=true, desc = "vscode: wrap lines j" })
-- vim.keymap.set("n", "k", [[v:count == 0 ? 'gk' : 'k']], { expr = true, desc = "vscode: wrap lines k" })
-- vim.keymap.set("n", "j", [[v:count == 0 ? 'gj' : 'j']], { expr = true, desc = "vscode: wrap lines j" })

-- lsp navigation
map("n", "gr", function() vscode.action "editor.action.goToReferences" end, "vscode: go to references")
map("n", "gI", function() vscode.action "editor.action.goToImplementation" end, "vscode: go to implementation")
map("n", "gd", function() vscode.action "editor.action.peekDefinition" end, "vscode: preview definition")
map("n", "<leader>gd", function() vscode.action "editor.action.revealDefinition" end, "vscode: go to definition")
map("n", "gt", function() vscode.action "editor.action.peekTypeDefinition" end, "vscode: preview definition")
map("n", "<leader>gt", function() vscode.action "editor.action.goToTypeDefinition" end, "vscode: go to type definition")
map("n", "ga", function() vscode.action "editor.action.quickFix" end, "vscode: code action")
map("n", "gD", function() vscode.action "editor.action.revealDeclaration" end, "vscode: go to declaration")
map("n", "<leader>gD", function() vscode.action "editor.action.peekDeclaration" end, "vscode: preview declaration")
map("n", "gs", function() vscode.action "workbench.action.gotoSymbol" end, "vscode: go to symbol")
map("n", "<leader>rn", function() vscode.action "editor.action.rename" end, "vscode: rename")

-- diagnostic navigation
map("n", "]e", function() vscode.action "editor.action.marker.nextInFiles" end, "vscode: go to next diagnostic")
map("n", "[e", function() vscode.action "editor.action.marker.prevInFiles" end, "vscode: go to previous diagnostic")

-- git change navigation
map("n", "[c", function() vscode.action "workbench.action.editor.nextChange" end, "vscode: next git hunk")
map("n", "]c", function() vscode.action "workbench.action.editor.previousChange" end, "vscode: previous git hunk")

-- buffer navigation
map("n", "<leader>h", function()
  local count = vim.v.count == 0 and 1 or vim.v.count
  for i = 1, count do
    vscode.action "workbench.action.previousEditor"
  end
end, "vscode: go to previous editor")

map("n", "<leader>l", function()
  local count = vim.v.count == 0 and 1 or vim.v.count
  for i = 1, count do
    vscode.action "workbench.action.nextEditor"
  end
end, "vscode: go to preview editor")

map("n", "<leader>H", function()
  local count = vim.v.count == 0 and 1 or vim.v.count
  for i = 1, count do
    vscode.action "workbench.action.moveEditorLeftInGroup"
  end
end, "vscode: move editor left")

map("n", "<leader>L", function()
  local count = vim.v.count == 0 and 1 or vim.v.count
  for i = 1, count do
    vscode.action "workbench.action.moveEditorRightInGroup"
  end
end, "vscode: move editor right")

map("n", "<leader>bb", function() vscode.action "workbench.action.closeActiveEditor" end, "vscode: close current buffer")
map("n", "<leader>bo", function() vscode.action "workbench.action.closeActiveEditor" end, "vscode: close other buffers")
map("n", "<leader>bu", function() vscode.action "workbench.action.closeUnmodifiedEditors" end, "vscode: close unmodified buffers")
map("n", "<leader>bh", function() vscode.action "workbench.action.closeEditorsToTheLeft" end, "vscode: close left buffers")
map("n", "<leader>bl", function() vscode.action "workbench.action.closeEditorsToTheRight" end, "vscode: close right buffers")

-- create file
map("n", "<leader>af", function() vscode.action "explorer.newFile" end, "vscode: new file")
map("n", "<leader>ad", function() vscode.action "explorer.newFolder" end, "vscode: new folder")

-- file search
map("n", "<leader>sf", function() vscode.action "workbench.action.quickOpen" end, "vscode: search files")
map("n", "<leader>sr", function() vscode.action "workbench.action.openRecent" end, "vscode: search old files")
map("n", "<leader>sg", function() vscode.action "workbench.action.findInFiles" end, "vscode: find in files")
map("n", "<leader>ss", function() vscode.action "actions.find" end, "vscode: find in current file")
map("n", "<leader>sx", function() vscode.action "editor.action.startFindReplaceAction" end, "vscode: find and replace in current file")

-- toggle explore
map("n", "<leader>te", function() vscode.action "workbench.action.toggleSidebarVisibility" end, "vscode: toggle side bar")
map("n", "<leader>fe", function() vscode.action "workbench.view.explorer" end, "vscode: fouce explorer")
-- copilot view
map("n", "<leader>fa", function() vscode.action "codeium.openChatView" end, "vscode: fouce AI")

-- toggle terminal
map("n", "<leader>tt", function() vscode.action "workbench.action.terminal.toggleTerminal" end, "vscode: fouce")


-- horizontal scroll
map("n", "<leader>zh", function()
  for i = 1, 5 do
    vscode.action "scrollLeft"
  end
end, "vscode: scroll left")

map("n", "<leader>zl", function()
  for i = 1, 5 do
    vscode.action "scrollRight"
  end
end, "vscode: scroll right")

-- code fold/unfold
-- map("n", "zO", function() vscode.action "editor.unfoldRecursively" end, "vscode: recursive unfold")
-- map("n", "zC", function() vscode.action "editor.foldRecursively" end, "vscode: recursive fold")
-- map("n", "za", function() vscode.action "editor.toggleFold" end, "vscode: toggle fold")
-- map("n", "zM", function() vscode.action "editor.foldAll" end, "vscode: fold all")
-- map("n", "zR", function() vscode.action "editor.unfoldAll" end, "vscode: unfold all")

-- window split
map("n", "<leader>sp", function() vscode.action "workbench.action.splitEditorDown" end, "vscode: horizontal split")
map("n", "<leader>vp", function() vscode.action "workbench.action.splitEditorRight" end, "vscode: vertical split")

map("n", "<C-Up>", function() vscode.action "workbench.action.increaseViewHeight" end, "vscode: increase view height")
map("n", "<C-Left>", function() vscode.action "workbench.action.increaseViewWidth" end, "vscode: increase view width")
map("n", "<C-Down>", function() vscode.action "workbench.action.decreaseViewHeight" end, "vscode: decrease view height")
map("n", "<C-Right>", function() vscode.action "workbench.action.decreaseViewWidth" end, "vscode: decrease view width")

-- debug
map("n", "<leader>dr", function() vscode.action "workbench.action.debug.start" end, "vscode: debug run")
map("n", "<leader>ds", function() vscode.action "workbench.action.debug.stop" end, "vscode: debug stop")

map("n", "<leader>dh", function() vscode.action "editor.debug.action.runToCursor" end, "vscode: debug run to cursor")
map("n", "<leader>db", function() vscode.action "editor.debug.action.toggleBreakpoint" end, "vscode: debug toggle breakpoint")
map("n", "<leader>dc", function() vscode.action "editor.debug.action.conditionalBreakpoint" end, "vscode: debug set condition  breakpoint")
map("n", "<leader>de", function() vscode.action "editor.debug.action.selectionToRepl" end, "vscode: debug eval expression")

map({ "n", "x" }, "[b", function() vscode.action "editor.debug.action.goToNextBreakpoint" end, "vscode: debug go to next breakpoint")
map({ "n", "x" }, "]b", function() vscode.action "editor.debug.action.goToPreviousBreakpoint" end, "vscode: debug go to previous breakpoint")


-- run
map("n", "<leader>rr", function() vscode.action "code-runner.run" end, "vscode: code run")
map("n", "<leader>rs", function() vscode.action "code-runner.stop" end, "vscode: code stop")

-- translate
map("x", "<leader><leader>e", function() vscode.action "extension.translateTextPreferred" end, "vscode: translate")

-- stylua: ignore end
