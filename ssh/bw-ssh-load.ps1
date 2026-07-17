#Requires -Version 5.1
param(
    [string]$ItemName,
    [string]$KeyName,
    [switch]$DryRun,
    [switch]$Pub
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

PreCheck

Write-Host "Unlocking Bitwarden..."
$env:BW_SESSION = bw unlock --raw
if (-not $env:BW_SESSION) { Write-Host "✗ 解锁失败"; exit 1 }

if ($Pub) {
    if (-not $ItemName) { Write-Host "✗ -Pub 需要指定条目名"; exit 1 }

    # 解析 文件夹名/条目名 格式
    if ($ItemName -match '/') {
        $parts = $ItemName -split '/', 2
        $FolderName = $parts[0]
        $ItemName   = $parts[1]
    } else {
        $FolderName = ""
    }

    try {
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
        if (-not $detail.sshKey.publicKey) { Write-Host "✗ 条目无公钥"; exit 1 }
        if (-not $DryRun) {
            Write-Output $detail.sshKey.publicKey
        } else {
            Write-Host "[DRY RUN] 将输出 $ItemName 的公钥到 stdout"
        }
    } finally {
        Cleanup
    }
    return
}

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
        if (-not $KeyName) { $KeyName = $ItemName -replace '[^\w.-]', '_' }

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
        if (-not $detail.sshKey.privateKey) { Write-Host "✗ 条目缺少私钥"; exit 1 }

        if (-not $DryRun) {
            $detail.sshKey.privateKey | ssh-add - | Out-Null
        }
        $tag = if ($DryRun) { "[DRY RUN]" } else { "✔" }
        Write-Host "$tag $ItemName → agent"

        if ($detail.sshKey.publicKey) {
            if (-not $DryRun) {
                $detail.sshKey.publicKey | Out-File -Encoding ASCII "$env:USERPROFILE\.ssh\$KeyName.pub"
            }
            Write-Host "$tag .pub → ~/.ssh/$KeyName.pub"
        }
    }
} finally {
    Cleanup
}

if (-not $DryRun) { ssh-add -l }
Write-Host "Done."
