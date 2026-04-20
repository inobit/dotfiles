#Requires AutoHotkey v2.0
#SingleInstance Force

apps := ["ahk_exe chrome.exe", "ahk_exe datagrip64.exe", "ahk_exe idea64.exe"]

for (app in apps) {
     HotIfWinActive(app)
     Hotkey("^n", (*) => Send("{Down}"))
     Hotkey("^p", (*) => Send("{Up}"))
}

#HotIf WinActive("ahk_exe Obsidian.exe")
^f::Right
#HotIf

^!p::Run("wezterm-gui.exe")

; 支持 jj 双击和 ESC 切换的应用列表
global DOUBLE_J_THRESHOLD := 300
global lastJTime := 0
global jPressed := false

global TARGET_APPS := [
    "ahk_exe Obsidian.exe",
    "ahk_exe wezterm-gui.exe",
    "ahk_exe WindowsTerminal.exe",
    "ahk_class CASCADIA_HOSTING_WINDOW_CLASS"
]

; 检测是否为目标应用
isTargetApp() {
    global TARGET_APPS
    for (app in TARGET_APPS) {
        if (WinActive(app)) {
            return true
        }
    }
    return false
}

; 使用函数动态判断当前窗口
#HotIf isTargetApp()

$j::HandleJKey
$Esc::HandleEscKey

#HotIf



HandleJKey(*) {
    global lastJTime, jPressed, DOUBLE_J_THRESHOLD

    ; 只在中文输入法下检测双击
    if (!isEnglishMode()) {
        currentTime := A_TickCount

        if (jPressed && (currentTime - lastJTime < DOUBLE_J_THRESHOLD)) {
            ; 双击 j：发送 2 次 ESC，然后切换英文
            Send("{Esc}{Esc}")
            Sleep(100)
            Send("{Shift}")
            jPressed := false
            return
        }

        lastJTime := currentTime
        jPressed := true
        SetTimer(ResetJState, -DOUBLE_J_THRESHOLD)
    }

    Send("j")
    return
}

HandleEscKey(*) {
    Send("{Esc}")
    Sleep(100)

    if (!isEnglishMode()) {
        Send("{Shift}")
    }
    return
}

ResetJState() {
    global jPressed := false
}

; ========== 检测输入法状态 ==========
isEnglishMode() {
    DetectHiddenWindows True
    hWnd := WinGetID("A")
    if (!hWnd) {
        return true
    }

    imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", hWnd, "Uint")
    if (!imeWnd) {
        return true
    }

    result := SendMessage(
        0x283,      ; WM_IME_CONTROL
        0x001,      ; IMC_GETCONVERSIONMODE
        0, ,
        "ahk_id " imeWnd
    )

    return result == 0  ; 0 = 英文，非0 = 中文
}