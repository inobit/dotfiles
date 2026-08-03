# editor
$env:EDITOR = "nvim"

# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

$_completionsDir = "$PSScriptRoot\completions"
$_starshipInit = "$_completionsDir\starship-init.ps1"
if (Test-Path $_starshipInit) {
    . $_starshipInit
} else {
    Invoke-Expression (&starship init powershell)
}

# Import-Module posh-git
# $omp_config = Join-Path -Path $ENV:USERPROFILE -ChildPath ".\powerlevel10k_lean.omp.json"
# oh-my-posh init pwsh --config $omp_config | Invoke-Expression

Import-Module -Name Terminal-Icons

# PSReadLine（PS7 已自动加载，无需 Import-Module）
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# tab for auto complete
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete

# undo
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo

#  search backward
Set-PSReadLineKeyHandler -Key "Ctrl+p" -Function HistorySearchBackward

# search forward
Set-PSReadLineKeyHandler -Key "Ctrl+n" -Function HistorySearchForward

#  remove ctrl space(conflict with tmux)
Remove-PSReadLineKeyHandler -Chord Ctrl+SpaceBar

# Alias
# Set-Alias ll ls
Set-Alias vim nvim
Set-Alias grep findstr


# git alias
function gsb { git status --short --branch @args }
function gss { git status --short @args }
function gsb { git status  @args }
function glog { git log --oneline --decorate --graph @args }
function glg { git log --stat }
function ggp { git push }
function ggl { git pull }

# wezterm
if (Get-Command -Name "wezterm" -ErrorAction SilentlyContinue) {
  Set-Alias wz wezterm
  function wzc { wezterm connect @args }
  function wzcs { wezterm cli spawn --domain-name @args }
}

# fzf
# replace 'Ctrl+t' and 'Ctrl+r' with your preferred bindings:
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -TabExpansion
Set-PsFzfOption -TabCompletionPreviewWindow 'right|down|hidden'
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }


function GetChildItemUnix ($path) {
  Get-ChildItem $path | Format-Table  -AutoSize
  # Get-ChildItem $path | Select-Object Mode, @{n='LastWriteTime';e={'{0:yyyy-MM-dd HH:mm:ss}' -f $_.LastWriteTime}}, Length,@{N='Name';E={if($_.Target) {$_.Name+' -> '+$_.Target} else {$_.Name}}}
}

Set-Alias ll GetChildItemUnix

if (Get-Command -Name "bat" -ErrorAction SilentlyContinue) {
  Set-Alias cat bat
}

# Admin shortcut
function admin { Start-Process wezterm-gui -Verb RunAs }

# Utilities
# lockkill — 查找并结束占用文件/目录的进程（需 scoop install sysinternals）
function lockkill {
    param(
        [Parameter(Mandatory, Position = 0)][string]$Path,
        [switch]$DryRun
    )

    if (-not (Get-Command handle64 -ErrorAction SilentlyContinue)) {
        Write-Host "handle64 not found. Run:" -ForegroundColor Yellow
        Write-Host "  scoop install sysinternals" -ForegroundColor Green
        return
    }

    $output = & handle64 -accepteula $Path 2>$null
    if (-not $output) {
        Write-Host "No process found locking: $Path" -ForegroundColor Gray
        return
    }

    $items = @($output | ForEach-Object { if ($_ -match '(.+?)\s+pid:\s*(\d+)') { [pscustomobject]@{ Process = $Matches[1]; PID = [int]$Matches[2] } } })
    if (-not $items) {
        Write-Host "Could not parse PID from handle64 output." -ForegroundColor Yellow
        return
    }

    $items | Sort-Object PID -Unique | ForEach-Object {
        if ($DryRun) {
            Write-Host "Would kill: $($_.Process) (PID $($_.PID))" -ForegroundColor DarkYellow
        } else {
            Write-Host "Killing $($_.Process) (PID $($_.PID)) ..." -ForegroundColor Red
            Stop-Process -Id $_.PID -Force -ErrorAction SilentlyContinue
        }
    }

    if (-not $DryRun) { Write-Host "Done." -ForegroundColor Green }
}

function which ($command) {
    $result = Get-Command -Name $command -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
    if ($result) {
        return $result
    }
    Write-Host "$command not found" -ForegroundColor Yellow
}

# ln
function ln {
    param(
        [switch]$s,  # soft link (symbolic), default 为 hard link
        [switch]$f,  # force overwrite
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Target,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Link
    )

    if (-not (Test-Path $Target)) {
        Write-Error "Target path '$Target' does not exist"
        return
    }

    $isDir = Test-Path -Path $Target -PathType Container

    if ($s) {
        $itemType = 'SymbolicLink'
        $typeLabel = 'symbolic'
    } else {
        if ($isDir) {
            Write-Error "Hard link target cannot be a directory, use -s for symbolic link"
            return
        }
        $itemType = 'HardLink'
        $typeLabel = 'hard'
    }

    if ((Test-Path $Link) -and -not $f) {
        Write-Error "Link path '$Link' already exists, use -f to force overwrite"
        return
    }

    $params = @{
        Path     = $Link
        ItemType = $itemType
        Target   = $Target
    }
    if ($f) { $params.Force = $true }

    try {
        New-Item @params -ErrorAction Stop | Out-Null
        Write-Host "Created $typeLabel link: $Link -> $Target"
    }
    catch {
        Write-Error "Failed to create $typeLabel link: $_"
    }
}

# color mode
function Get-TtyColorMode {
    if ($env:TTY_COLOR_MODE -in @('light', 'dark')) {
        return $env:TTY_COLOR_MODE
    }
    $env:TTY_COLOR_MODE = 'dark'
    return 'dark'
}

function Set-FzfOptions {
    $mode = Get-TtyColorMode

    $FZF_LIGHT_THEME = if ($mode -eq 'light') {
        '--color=fg:#797593,bg:#faf4ed,hl:#d7827e --color=fg+:#575279,bg+:#f2e9e1,hl+:#d7827e --color=border:#dfdad9,header:#286983,gutter:#faf4ed --color=spinner:#ea9d34,info:#56949f --color=pointer:#907aa9,marker:#b4637a,prompt:#797593'
    } else {
        ''
    }

    $baseOpts = "$FZF_LIGHT_THEME --height 60% --layout reverse --border"
    $env:FZF_DEFAULT_OPTS = $baseOpts
    # PSFzf 读取的是这个变量，必须同步更新颜色
    $env:_PSFZF_FZF_DEFAULT_OPTS = "--tmux bottom,60% $baseOpts"
}

Set-FzfOptions

Set-Alias -Name tcm -Value Get-TtyColorMode

function sops {
    $bwFolderName = "keys"
    $bwItemName   = "secrets_vault_key"

    try {
        Write-Host "Unlocking Bitwarden..." -ForegroundColor Yellow
        $env:BW_SESSION = bw unlock --raw
        if (-not $env:BW_SESSION) {
            Write-Error "sops: Bitwarden unlock failed"
            return
        }
        bw sync | Out-Null

        # 按文件夹名获取 folder ID
        $folder = bw list folders |
            ConvertFrom-Json |
            Where-Object { $_.name -eq $bwFolderName } |
            Select-Object -First 1
        if (-not $folder) {
            Write-Error "sops: Folder '$bwFolderName' not found"
            return
        }
        $allItems = bw list items --folderid $folder.id --search $bwItemName |
            ConvertFrom-Json

        # 按名称 + 类型 (5 = SSH Key) 精确匹配，0 或多条均报错
        $matches = @($allItems | Where-Object { $_.type -eq 5 -and $_.name -eq $bwItemName })
        if ($matches.Count -eq 0) {
            Write-Error "sops: No SSH Key item named '$bwItemName' in folder '$bwFolderName'"
            return
        }
        if ($matches.Count -gt 1) {
            Write-Error "sops: Multiple SSH Key items ($($matches.Count)) match '$bwItemName'"
            $matches | ForEach-Object { Write-Host "  - $($_.name) ($($_.id))" -ForegroundColor Yellow }
            return
        }
        $itemId = $matches[0].id

        $env:SOPS_AGE_SSH_PRIVATE_KEY_CMD = "powershell -NoProfile -Command `"(bw get item $itemId | ConvertFrom-Json).sshKey.privateKey`""
        & (Get-Command sops -CommandType Application).Source @args
    } finally {
        Remove-Item Env:SOPS_AGE_SSH_PRIVATE_KEY_CMD -ErrorAction SilentlyContinue
        if ($env:BW_SESSION) {
            $null = bw lock 2>&1
            Remove-Item Env:BW_SESSION -ErrorAction SilentlyContinue
        }
    }
}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
# $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
# if (Test-Path($ChocolateyProfile)) {
#   Import-Module "$ChocolateyProfile"
# }

# uv auto complete（优先用静态缓存，避免每次启动 fork Python 进程）
$_uvCompletion = "$_completionsDir\uv-completion.ps1"
if (Test-Path $_uvCompletion) { . $_uvCompletion } else { (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression }
$_uvxCompletion = "$_completionsDir\uvx-completion.ps1"
if (Test-Path $_uvxCompletion) { . $_uvxCompletion } else { (& uvx --generate-shell-completion powershell) | Out-String | Invoke-Expression }

# fnm — 实时生成 env 脚本（不缓存，避免 PATH 快照过时）
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
$_fnmComp = "$_completionsDir\fnm-completions.ps1"
if (Test-Path $_fnmComp) { . $_fnmComp } else { fnm completions --shell powershell | Out-String | Invoke-Expression }

# 升级工具后运行此函数刷新静态 completion 缓存
function Update-Completions {
    $d = "$PSScriptRoot\completions"
    New-Item -ItemType Directory -Force -Path $d | Out-Null
    starship init powershell | Out-String | Set-Content "$d\starship-init.ps1"
    fnm completions --shell powershell | Out-String | Set-Content "$d\fnm-completions.ps1"
    uv generate-shell-completion powershell | Out-String | Set-Content "$d\uv-completion.ps1"
    uvx --generate-shell-completion powershell | Out-String | Set-Content "$d\uvx-completion.ps1"
    Write-Host "Completions updated: $d" -ForegroundColor Green
}

# === 类 Linux 后台任务：bg / jobs / fg / kill ===
# 用法：bg "ssh -N -L 8080:localhost:80 host" 或 bg { ssh -N -L 8080:localhost:80 host }
#       jobs           查看后台任务（Job / 状态 / 命令）
#       fg %<Id>       阻塞等待作业并回放输出（Ctrl+C 仅中断等待，作业仍在后台）
#       kill %<Id>     终止后台任务（% 开头 → job id，如 kill %1）
#       kill %<name>   按作业名匹配终止，如 kill %sleep
#       kill <pid>     杀进程（不带 % 即按 PID）
# 注：输出统一显示 [N]（同 bash 的 jobs 格式）；%N 仅作为命令参数引用语法
Remove-Alias kill -Force -ErrorAction SilentlyContinue
function bg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Command
    )

    $sb = if ($Command -is [scriptblock]) { $Command } else { [scriptblock]::Create($Command) }
    $job = Start-Job -ScriptBlock $sb -Name ($Command.ToString() -replace '\s+', ' ').Trim()
    Write-Host ("[{0}] {1}" -f $job.Id, $job.Name)
}

function jobs {
    Get-Job |
        Select-Object @{n = 'Job'; e = { '[' + $_.Id + ']' } }, State, @{n = 'Command'; e = { $_.Name } } |
        Format-Table -AutoSize
}

function kill {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Target
    )

    if ($Target -match '^%(?<id>\d+)$') {
        $job = Get-Job -Id ([int]$Matches['id']) -ErrorAction SilentlyContinue
        if (-not $job) { Write-Host "kill: no such job %$($Matches['id'])" -ForegroundColor Yellow; return }
        Stop-Job -Id $job.Id -ErrorAction SilentlyContinue
        Remove-Job -Id $job.Id -Force -ErrorAction SilentlyContinue
        Write-Host "killed job [$($job.Id)] $($job.Name)"
    }
    elseif ($Target -match '^%(?<name>\S+)$') {
        $jobs = @(Get-Job -Name "$($Matches['name'])*" -ErrorAction SilentlyContinue)
        if ($jobs.Count -eq 0) { Write-Host "kill: no such job %$($Matches['name'])" -ForegroundColor Yellow; return }
        if ($jobs.Count -gt 1) {
            Write-Host "kill: ambiguous job name %$($Matches['name']):" -ForegroundColor Yellow
            $jobs | ForEach-Object { Write-Host ("  %{0} {1}" -f $_.Id, $_.Name) }
            return
        }
        Stop-Job -Id $jobs[0].Id -ErrorAction SilentlyContinue
        Remove-Job -Id $jobs[0].Id -Force -ErrorAction SilentlyContinue
        Write-Host "killed job [$($jobs[0].Id)] $($jobs[0].Name)"
    }
    else {
        Stop-Process -Id ([int]$Target) -Force
        Write-Host "killed process $Target"
    }
}

function fg {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Target
    )

    if ($Target -notmatch '^%(?<id>\d+)$') {
        Write-Host "usage: fg %<jobid>  (e.g. fg %1)" -ForegroundColor Yellow
        return
    }
    $job = Get-Job -Id ([int]$Matches['id']) -ErrorAction SilentlyContinue
    if (-not $job) { Write-Host "fg: no such job %$($Matches['id'])" -ForegroundColor Yellow; return }

    $jobId = $job.Id
    try {
        Receive-Job -Id $jobId -Wait
    }
    finally {
        # Ctrl+C 后 Write-Host 会静默失败（PowerShell 已知问题 #19988/#23786），
        # 用 Console 直接写，并临时改前景色实现黄色提示
        $state = (Get-Job -Id $jobId -ErrorAction SilentlyContinue).State
        $saved = [System.Console]::ForegroundColor
        [System.Console]::ForegroundColor = [ConsoleColor]::Yellow
        if ($state -in @('Completed', 'Failed', 'Stopped')) {
            [System.Console]::WriteLine("tip: 作业 [$jobId] 已结束，状态: $state")
        }
        else {
            [System.Console]::WriteLine("tip: 等待被中断，作业 [$jobId] 仍在后台，用 kill %$jobId 终止")
        }
        [System.Console]::ForegroundColor = $saved
    }
}
