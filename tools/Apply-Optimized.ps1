param(
    [string]$SourceZip,
    [string]$OutputZip
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$packageRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $packageRoot 'changes.json'
$langRoot = Join-Path $packageRoot 'shaders\lang'
if (-not (Test-Path -LiteralPath $manifestPath)) {
    $manifestPath = Join-Path $packageRoot 'patches\optimized\changes.json'
    $langRoot = Join-Path $packageRoot 'patches\optimized\shaders\lang'
}
function Get-TextHash([string]$Text) {
    $hash = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-', '').ToLowerInvariant() }
    finally { $hash.Dispose() }
}
function Read-Normalized([string]$Path) {
    return [IO.File]::ReadAllText($Path).Replace("`r`n", "`n").Replace("`r", "`n")
}
if (-not $SourceZip) {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.Title = '选择从官网下载的 BSL 10.1.8 原版 ZIP'
    $dialog.Filter = 'BSL 光影 ZIP (*.zip)|*.zip'
    if ($dialog.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { Write-Host '已取消。'; exit 0 }
    $SourceZip = $dialog.FileName
    $dialog.Dispose()
}
$SourceZip = (Resolve-Path -LiteralPath $SourceZip).Path
if (-not $OutputZip) {
    $OutputZip = Join-Path (Split-Path -Parent $SourceZip) 'BSL_v10.1.8_zhCN_1070Ti.zip'
}
$OutputZip = [IO.Path]::GetFullPath($OutputZip)
if ([string]::Equals($SourceZip, $OutputZip, [StringComparison]::OrdinalIgnoreCase)) { throw '输出路径不能与原版 ZIP 相同。' }
if (Test-Path -LiteralPath $OutputZip) { throw "输出文件已存在，请先改名保存或指定新的输出路径：$OutputZip" }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $OutputZip) -PathType Container)) { throw '输出目录不存在。' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.format -ne 1 -or $manifest.base_version -ne '10.1.8') { throw '补丁清单格式或基础版本不正确。' }
$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$tempRoot = [IO.Path]::GetFullPath((Join-Path $tempBase ('BSL-zhCN-' + [Guid]::NewGuid().ToString('N'))))
if (-not $tempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) { throw '临时路径检查失败。' }
[IO.Directory]::CreateDirectory($tempRoot) | Out-Null
$outputCreated = $false
try {
    $zip = [IO.Compression.ZipFile]::OpenRead($SourceZip)
    try {
        foreach ($entry in $zip.Entries) {
            $destination = [IO.Path]::GetFullPath((Join-Path $tempRoot $entry.FullName))
            if (-not $destination.StartsWith($tempRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
                throw '原包包含不安全的归档路径。'
            }
        }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($SourceZip, $tempRoot)
    $shaderRoot = Join-Path $tempRoot 'shaders'
    if (-not (Test-Path -LiteralPath $shaderRoot -PathType Container)) { throw '没有找到 shaders 文件夹，请选择官方完整光影 ZIP。' }

    # 先验证全部文件。遇到错误版本或已有其他魔改时，不产生输出包。
    $texts = @{}
    foreach ($file in $manifest.files) {
        $path = [IO.Path]::GetFullPath((Join-Path $shaderRoot $file.path))
        if (-not $path.StartsWith($shaderRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw '补丁路径检查失败。' }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "原包缺少文件：$($file.path)" }
        $text = Read-Normalized $path
        if ((Get-TextHash $text) -ne $file.base_sha256) { throw "基础文件不匹配：$($file.path)。仅支持官方 BSL 10.1.8；请重新下载原版，不要使用已有魔改。" }
        $texts[$file.path] = $text
    }
    $utf8 = New-Object Text.UTF8Encoding($false)
    foreach ($file in $manifest.files) {
        $lines = New-Object 'Collections.Generic.List[string]'
        $lines.AddRange([string[]]$texts[$file.path].Split([char]10))
        $ops = @($file.ops)
        for ($i = $ops.Count - 1; $i -ge 0; $i--) {
            $op = $ops[$i]
            $lines.RemoveRange([int]$op.start, [int]$op.end - [int]$op.start)
            $lines.InsertRange([int]$op.start, [string[]]@($op.lines))
        }
        $result = [string]::Join("`n", $lines.ToArray())
        if ((Get-TextHash $result) -ne $file.patched_sha256) { throw "生成结果校验失败：$($file.path)" }
        [IO.File]::WriteAllText((Join-Path $shaderRoot $file.path), $result, $utf8)
    }
    [IO.Directory]::CreateDirectory((Join-Path $shaderRoot 'lang')) | Out-Null
    foreach ($name in @('zh_CN.lang', 'zh_cn.lang')) {
        Copy-Item -LiteralPath (Join-Path $langRoot $name) -Destination (Join-Path $shaderRoot ('lang\' + $name)) -Force
    }
    [IO.Compression.ZipFile]::CreateFromDirectory($tempRoot, $OutputZip, [IO.Compression.CompressionLevel]::Optimal, $false)
    $outputCreated = $true
    Write-Host ''
    Write-Host '已生成汉化优化魔改包：' -ForegroundColor Green
    Write-Host $OutputZip
    Write-Host '原版 ZIP 保留不变。将新包放入 shaderpacks，在游戏中选择“1070 Ti｜保真均衡”。'
    Write-Host '这是非官方魔改版，不适用于所有显卡；未提供游戏内实测 FPS 保证。'
} catch {
    # 原包始终只读；失败时仅清理本次创建的输出。
    if ($outputCreated -and (Test-Path -LiteralPath $OutputZip)) { Remove-Item -LiteralPath $OutputZip }
    throw
} finally {
    $checkedTempRoot = [IO.Path]::GetFullPath($tempRoot)
    if ($checkedTempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and ([IO.Path]::GetFileName($checkedTempRoot) -match '^BSL-zhCN-[0-9a-f]{32}$')) {
        Remove-Item -LiteralPath $checkedTempRoot -Recurse -Force
    }
}
