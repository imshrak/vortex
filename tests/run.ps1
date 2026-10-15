param(
    [Parameter(Mandatory = $true)][string]$Luau,
    [Parameter(Mandatory = $true)][string]$Compiler
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sources = Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object { $_.Extension -in '.lua', '.luau' }
foreach ($source in $sources) {
    & $Compiler --null $source.FullName
    if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $($source.FullName)" }
}
$parts = @((Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'RobloxMock.luau')))
foreach ($module in @(@('Library', 'Library.lua'), @('SaveManager', 'addons/SaveManager.lua'), @('ThemeManager', 'addons/ThemeManager.lua'))) {
    $moduleSource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot $module[1])
    $parts += "local $($module[0]) = (function()`n$moduleSource`nend)()"
}
$parts += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Appearance.luau')
$parts += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Customization.luau')
$parts += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Behavior.luau')
$runnerPath = Join-Path ([System.IO.Path]::GetTempPath()) ('vortex-test-' + [guid]::NewGuid().ToString('N') + '.luau')
try {
    [System.IO.File]::WriteAllText($runnerPath, ($parts -join "`n"))
    & $Luau $runnerPath
    if ($LASTEXITCODE -ne 0) { throw 'Behavior checks failed' }
} finally {
    if (Test-Path -LiteralPath $runnerPath) { Remove-Item -LiteralPath $runnerPath }
}
