#Requires -Version 5.1
<#
用法:
  bw-ssh-load.ps1                                # 批量: SSH Key 全部入 agent (ExcludeKeys 可排除)
  bw-ssh-load.ps1 -ItemName "SSH Keys/A"         # 单 key: 私钥入 agent + 公钥存 ~/.ssh/A.pub
  bw-ssh-load.ps1 -ItemName "A" -PubName C:\keys\x.pub   # 自定义公钥路径/文件名, 目录须存在
  bw-ssh-load.ps1 -ItemName "A" -NoAgent         # 只写公钥文件, 不碰 agent
  bw-ssh-load.ps1 -ItemName "A" -NoPub           # 只入 agent, 不写公钥文件
  bw-ssh-load.ps1 -ItemName "A" -NoAgent -NoPub  # ✗ 无操作, 拒绝
  bw-ssh-load.ps1 -DryRun                        # 预演

参数:
  -ItemName   条目名, 支持 "文件夹/条目" 格式
  -NoAgent    私钥不写入 ssh-agent
  -NoPub      不保存公钥文件
  -PubName    公钥文件名; 格式 (路径)?文件名(.pub)?, 缺省用默认名, 目录须已存在; 仅 -NoPub 未指定时生效
  -DryRun     预演, 不实际执行
#>
param(
    [string]$ItemName,
    [switch]$NoAgent,
    [switch]$NoPub,
    [string]$PubName,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# ============================================================
# 配置区
#
# FolderNames: 限制只从这些 Bitwarden 文件夹中加载
# PubKeyNames: 无参数模式下，仅对这些条目生成 .pub 文件
# ============================================================
$script:FolderNames = @(
    # "SSH Keys"
    # "Work"
)
$script:PubKeyNames = @(
    # "GitHub Personal"
    # "Work/GitHub"          # 文件夹名/条目名 格式
    # "Company Server"
)

# ExcludeKeys: 批量模式下不写入 ssh-agent 的条目
#   "文件夹/条目"  精确排除; "条目" 排除所有同名条目
$script:ExcludeKeys = @(
    # "SSH Keys/Old Key"
    # "Legacy Key"
)
# ============================================================

function PreCheck {
    if (-not (Get-Command bw -ErrorAction SilentlyContinue)) {
        Write-Host "✗ 'bw' 未安装。scoop install bitwarden-cli"; exit 1
    }
    if (-not (Get-Command ssh-add -ErrorAction SilentlyContinue)) {
        Write-Host "✗ 'ssh-add' 未安装"; exit 1
    }

    if (-not $DryRun) {
        $null = ssh-add -l 2>&1
        if ($LASTEXITCODE -eq 2) {
            Write-Host "✗ ssh-agent 未运行。请执行: Start-Service ssh-agent"; exit 1
        }

        $sshDir = "$env:USERPROFILE\.ssh"
        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }
    }
}

function Cleanup {
    if ($env:BW_SESSION) {
        $null = bw lock 2>&1
        Remove-Item Env:BW_SESSION -ErrorAction SilentlyContinue
    }
}

function Resolve-PubPath {
    param([string]$ItemName, [string]$PubNameArg)
    $dir  = if ($PubNameArg) { Split-Path -Parent $PubNameArg } else { "" }
    $leaf = if ($PubNameArg) { Split-Path -Leaf $PubNameArg } else { "" }

    if ($PubNameArg) {
        if (-not $leaf) { Write-Host "✗ -PubName 缺少文件名: $PubNameArg"; exit 1 }
        if ($dir) {
            if (-not (Test-Path -LiteralPath $dir)) { Write-Host "✗ 目录不存在: $dir"; exit 1 }
        } else {
            $dir = "$env:USERPROFILE\.ssh"
        }
        if (-not ($leaf -match '\.\w+$')) { $leaf += '.pub' }
    } else {
        $dir  = "$env:USERPROFILE\.ssh"
        $leaf = ($ItemName -replace '[^\w.-]', '_') + '.pub'
    }
    return (Join-Path $dir $leaf)
}

PreCheck

Write-Host "Unlocking Bitwarden..."
$env:BW_SESSION = bw unlock --raw
if (-not $env:BW_SESSION) { Write-Host "✗ 解锁失败"; exit 1 }

try {
    if (-not $ItemName) {
        # 无参数模式：按文件夹过滤后加载
        if ($FolderNames.Count -gt 0) {
            $folders = bw list folders | ConvertFrom-Json | Where-Object { $FolderNames -contains $_.name }
            $folderIds = $folders | ForEach-Object { $_.id }
            $items = bw list items | ConvertFrom-Json |
                Where-Object { $_.type -eq 5 -and $_.folderId -in $folderIds }
        } else {
            $items = bw list items | ConvertFrom-Json | Where-Object { $_.type -eq 5 }
        }
        if (-not $items) { Write-Host "没有找到 SSH Key 类型条目。"; return }

        # 预先获取文件夹 id → name 映射
        $folderMap = @{}
        bw list folders | ConvertFrom-Json | ForEach-Object { $folderMap[$_.id] = $_.name }

        # 应用排除列表 ExcludeKeys (精确 "文件夹/条目" 或宽松 "条目名")
        $exMatched = @{}
        $items = @($items | Where-Object {
            $fn = if ($_.folderId) { $folderMap[$_.folderId] } else { "" }
            foreach ($ex in $script:ExcludeKeys) {
                if ($ex -match '/') { $ef, $ek = $ex -split '/', 2; $isEx = ($_.name -eq $ek) -and ($fn -eq $ef) }
                else { $isEx = ($_.name -eq $ex) }
                if ($isEx) { $exMatched[$ex] = $true; Write-Host "  ⏭ 排除: $fn/$($_.name)"; return $false }
            }
            return $true
        })
        foreach ($ex in $script:ExcludeKeys) {
            if (-not $exMatched.ContainsKey($ex)) { Write-Host "  ⚠ 排除项未命中任何条目: $ex" }
        }

        $pubWritten = @{}

        foreach ($item in $items) {
            try {
                if (-not $DryRun) {
                    $item.sshKey.privateKey | ssh-add - 2>&1 | Out-Null
                }
                $tag = if ($DryRun) { "[DRY RUN]" } else { "✔" }
                Write-Host "  $tag $($item.name) → agent"
            } catch {
                Write-Host "  ⚠ $($item.name): 加载失败"; continue
            }

            if (-not $item.sshKey.publicKey) { continue }

            foreach ($pubEntry in $PubKeyNames) {
                if ($pubEntry -match '/') {
                    $parts = $pubEntry -split '/', 2
                    $pubFolder = $parts[0]
                    $pubItem   = $parts[1]
                } else {
                    $pubFolder = ""
                    $pubItem   = $pubEntry
                }
                if ($item.name -ne $pubItem) { continue }

                $itemFolderName = if ($item.folderId) { $folderMap[$item.folderId] } else { "" }
                if ($pubFolder -and $itemFolderName -ne $pubFolder) { continue }

                $safeName = $item.name -replace '[^\w.-]', '_'
                if ($pubWritten.ContainsKey($safeName)) {
                    Write-Host "✗ PUB_KEY_NAMES 冲突: '$safeName.pub' 匹配到多个条目"
                    Write-Host "  - $($pubWritten[$safeName])"
                    if ($itemFolderName) { Write-Host "  - $itemFolderName/$($item.name)" } else { Write-Host "  - $($item.name)" }
                    Write-Host "✗ 请用 '文件夹名/条目名' 格式消歧（如 '$itemFolderName/$($item.name)'）"
                    exit 1
                }
                if ($itemFolderName) { $pubWritten[$safeName] = "$itemFolderName/$($item.name)" } else { $pubWritten[$safeName] = $item.name }

                if (-not $DryRun) {
                    $item.sshKey.publicKey | Out-File -Encoding ASCII "$env:USERPROFILE\.ssh\$safeName.pub"
                }
                $tag = if ($DryRun) { "[DRY RUN]" } else { "✔" }
                Write-Host "    $tag .pub → ~/.ssh/$safeName.pub"
                break
            }
        }
    } else {
        # 单 key 模式：按名称（支持 文件夹名/条目名 格式）查找
        if ($ItemName -match '/') {
            $parts = $ItemName -split '/', 2
            $FolderName = $parts[0]
            $ItemName   = $parts[1]
        } else {
            $FolderName = ""
        }
        if ($FolderName) {
            $folder = bw list folders | ConvertFrom-Json | Where-Object { $_.name -eq $FolderName } | Select-Object -First 1
            if (-not $folder) { Write-Host "✗ 未找到文件夹: $FolderName"; exit 1 }
            $allItems = bw list items --folderid $folder.id --search $ItemName | ConvertFrom-Json
        } else {
            $allItems = bw list items --search $ItemName | ConvertFrom-Json
        }
        $matches = @($allItems | Where-Object { $_.type -eq 5 -and $_.name -eq $ItemName })

        if ($matches.Count -eq 0) {
            if ($FolderName) { Write-Host "✗ 文件夹 '$FolderName' 中未找到: $ItemName" } else { Write-Host "✗ 未找到: $ItemName" }
            exit 1
        }
        if ($matches.Count -gt 1) {
            Write-Host "✗ 有 $($matches.Count) 个条目匹配 '$ItemName'，请用 '文件夹名/条目名' 格式消歧："
            $matches | ForEach-Object { Write-Host "  - $($_.name)  [文件夹ID: $($_.folderId)]" }
            exit 1
        }

        $detail = bw get item $matches[0].id | ConvertFrom-Json
        if (-not $NoAgent -and -not $detail.sshKey.privateKey) { Write-Host "✗ 条目缺少私钥"; exit 1 }

        if ($NoAgent -and $NoPub) { Write-Host "✗ -NoAgent 且 -NoPub: 没有执行任何操作"; exit 1 }
        if (-not $NoPub -and -not $detail.sshKey.publicKey) { Write-Host "✗ 条目无公钥"; exit 1 }

        if (-not $NoAgent) {
            if (-not $DryRun) {
                $detail.sshKey.privateKey | ssh-add - | Out-Null
            }
            $tag = if ($DryRun) { "[DRY RUN]" } else { "✔" }
            Write-Host "$tag $ItemName → agent"
        }

        if (-not $NoPub) {
            $pubPath = Resolve-PubPath -ItemName $ItemName -PubNameArg $PubName
            if (-not $DryRun) {
                $detail.sshKey.publicKey | Out-File -Encoding ASCII $pubPath
            }
            $tag = if ($DryRun) { "[DRY RUN]" } else { "✔" }
            Write-Host "$tag .pub → $pubPath"
        }
    }
} finally {
    Cleanup
}

if (-not $DryRun) { ssh-add -l }
Write-Host "Done."
