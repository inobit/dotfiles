# set PowerShell to UTF-8
[console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding

Invoke-Expression (&starship init powershell)

# Import-Module posh-git
# $omp_config = Join-Path -Path $ENV:USERPROFILE -ChildPath ".\powerlevel10k_lean.omp.json"
# oh-my-posh init pwsh --config $omp_config | Invoke-Expression

Import-Module -Name Terminal-Icons

# PSReadLine
Import-Module PSReadLine
# Emacs mode
Set-PSReadLineOption -EditMode Emacs

# history source
Set-PSReadLineOption -PredictionSource HistoryAndPlugin

# cursor to end
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
$env:_PSFZF_FZF_DEFAULT_OPTS = '--height 60% --tmux bottom,60% --layout reverse --border'
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

# Utilities
function which ($command) {
  Get-Command -Name $command -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

# ln
function ln {
    param(
        [switch]$s,  # soft link
        [switch]$f,  # force
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Target,  #  target path
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Link     # link name
    )

    if (-not (Test-Path $Target)) {
        Write-Error "Target path '$Target' does not exist"
        return
    }

    $targetType = if (Test-Path -Path $Target -PathType Container) {
        "Directory"
    } else {
        "File"
    }

    # build params
    $params = @{
        Path = $Link
        ItemType = "SymbolicLink"
        Target = $Target
    }

    if ($f) {
        $params.Force = $true
    }

    # command map
    try {
        New-Item @params -ErrorAction Stop | Out-Null
        Write-Host "Created symbolic link: $Link -> $Target ($targetType)"
    }
    catch {
        Write-Error "Failed to create symbolic link: $_"
    }
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

if (Get-Command -Name mihomosh -ErrorAction SilentlyContinue) {
  (& mihomosh shell-completion powershell) | Out-String | Invoke-Expression
}

# fnm config
fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
fnm completions --shell powershell | Out-String | Invoke-Expression
