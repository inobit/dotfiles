apps := ["ahk_exe Obsidian.exe", "ahk_exe chrome.exe", "ahk_exe datagrip64.exe", "ahk_exe idea64.exe"]

for (app in apps) {
     HotIfWinActive(app)
     Hotkey("^n", (*) => Send("{Down}"))
     Hotkey("^p", (*) => Send("{Up}"))
}

#HotIf WinActive("ahk_exe Obsidian.exe")
^f::Right
#HotIf
