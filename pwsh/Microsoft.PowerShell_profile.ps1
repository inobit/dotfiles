# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Invoke-Expression (&starship init powershell)

# Import-Module posh-git
# $omp_config = Join-Path -Path $ENV:USERPROFILE -ChildPath ".\powerlevel10k_lean.omp.json"
# oh-my-posh init pwsh --config $omp_config | Invoke-Expression

Import-Module -Name Terminal-Icons

#PSReadLine
Import-Module PSReadLine
# 设置编辑模式,可以使用ctrl+a,ctrl+k,ctrl+e等类似bash的按键来编辑command
Set-PSReadLineOption -EditMode Emacs

# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# 每次回溯输入历史，光标定位于输入内容末尾
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# 设置 Tab 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

# 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo

# 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function HistorySearchBackward

# 设置向下键为前向搜索历史纪录
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function HistorySearchForward

# 移除ctrl space 和tmux冲突
Remove-PSReadLineKeyHandler -Chord Ctrl+SpaceBar

# Alias
# Set-Alias ll ls
Set-Alias vim nvim
Set-Alias grep findstr

function GetChildItemUnix ($path) {
  Get-ChildItem $path | Format-Table  -AutoSize
  # Get-ChildItem $path | Select-Object Mode, @{n='LastWriteTime';e={'{0:yyyy-MM-dd HH:mm:ss}' -f $_.LastWriteTime}}, Length,@{N='Name';E={if($_.Target) {$_.Name+' -> '+$_.Target} else {$_.Name}}}
}

Set-Alias ll GetChildItemUnix

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}


# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# uv config
$env:Path = "$env:USERPROFILE\.local\bin;" + $env:Path
# uv registe auto complete
(& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
(& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression
