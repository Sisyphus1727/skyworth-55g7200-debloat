<#
.SYNOPSIS
    恢复本项目卸载的酷开预装应用。

.DESCRIPTION
    读取 rollback.json（或 scripts/rollback.sample.json）中的包名与 APK 路径，
    通过 adb 执行 `pm install -r --user 0 <apk>` 把应用装回用户空间。

.PARAMETER TvHost
    电视的局域网 IP（无需带端口）。

.PARAMETER Pkg
    只恢复指定的包名。

.PARAMETER All
    恢复清单里的全部应用。

.PARAMETER Adb
    adb.exe 的路径；不填则使用 PATH 中的 adb。

.PARAMETER RollbackFile
    清单文件路径；不填则依次查找脚本目录下的 rollback.json、rollback.sample.json。

.EXAMPLE
    .\restore.ps1 -TvHost <电视IP> -All

.EXAMPLE
    .\restore.ps1 -TvHost <电视IP> -Pkg com.tianci.movieplatform
#>

param(
    [Parameter(Mandatory = $true)][string]$TvHost,
    [string]$Pkg,
    [switch]$All,
    [string]$Adb = "adb",
    [string]$RollbackFile
)

$ErrorActionPreference = "Continue"
$dev = "${TvHost}:5555"

if (-not (Get-Command $Adb -ErrorAction SilentlyContinue) -and -not (Test-Path $Adb)) {
    Write-Host "找不到 adb：$Adb" -ForegroundColor Red
    Write-Host "请安装 Android platform-tools，或用 -Adb 指定 adb.exe 的完整路径。"
    exit 1
}

if (-not $RollbackFile) {
    $candidates = @(
        (Join-Path $PSScriptRoot "rollback.json"),
        (Join-Path $PSScriptRoot "rollback.sample.json")
    )
    $RollbackFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $RollbackFile -or -not (Test-Path $RollbackFile)) {
    Write-Host "找不到回滚清单（rollback.json / rollback.sample.json）。" -ForegroundColor Red
    exit 1
}

Write-Host "回滚清单：$RollbackFile"
Write-Host "目标设备：$dev"

& $Adb start-server 2>&1 | Out-Null
& $Adb connect $dev 2>&1 | Out-Null

$state = (& $Adb devices 2>&1) -join "`n"
if ($state -notmatch [regex]::Escape($dev) + "\s+device") {
    Write-Host "无法连接设备，请确认：" -ForegroundColor Red
    Write-Host "  1. 电视已开机并与电脑在同一局域网"
    Write-Host "  2. 工厂菜单里 ADB 开关已打开"
    & $Adb devices
    exit 1
}

$list = Get-Content $RollbackFile -Raw | ConvertFrom-Json

if ($Pkg) {
    $list = $list | Where-Object { $_.pkg -eq $Pkg }
    if (-not $list) {
        Write-Host "清单里没有包名：$Pkg" -ForegroundColor Yellow
        exit 1
    }
}

if (-not $All -and -not $Pkg) {
    Write-Host ""
    Write-Host "请指定 -All 或 -Pkg <包名>。可选包："
    $list | ForEach-Object { "  {0}  ->  {1}" -f $_.pkg, $_.apk }
    exit 0
}

$ok = 0
$fail = 0
foreach ($item in $list) {
    Write-Host ("恢复 {0} ... " -f $item.pkg) -NoNewline
    $r = (& $Adb -s $dev shell "pm install -r --user 0 $($item.apk)" 2>&1) -join " "
    if ($r -match "Success") {
        Write-Host "OK" -ForegroundColor Green
        $ok++
    }
    else {
        Write-Host ("失败: " + $r.Trim()) -ForegroundColor Red
        $fail++
    }
}

Write-Host ""
Write-Host ("完成：成功 {0} 个，失败 {1} 个。" -f $ok, $fail)
Write-Host "若恢复了酷开桌面，需要重启并把 general_config.xml.bak 覆盖回去才能恢复原主页。"
Write-Host "改造完成后建议关闭 ADB：工厂菜单 → 通用设置 → ADB 开关 → 关（再断电重启）。"
