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
$librarySource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'Library.lua')
$parts += "local function newLibrary()`n$librarySource`nend"
foreach ($module in @(@('Project', 'designer/Project.lua'), @('Designer', 'Designer.lua'))) {
    $moduleSource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot $module[1])
    $parts += "local $($module[0]) = (function()`n$moduleSource`nend)()"
}
$parts += Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Designer.luau')
$runnerPath = Join-Path ([System.IO.Path]::GetTempPath()) ('vortex-test-' + [guid]::NewGuid().ToString('N') + '.luau')
$exportPath = Join-Path ([System.IO.Path]::GetTempPath()) ('vortex-export-' + [guid]::NewGuid().ToString('N') + '.luau')
try {
    [System.IO.File]::WriteAllText($runnerPath, ($parts -join "`n"))
    $output = & $Luau $runnerPath
    if ($LASTEXITCODE -ne 0) { throw 'Behavior checks failed' }
    $text = $output -join "`n"
    $match = [regex]::Match($text, '(?s)VORTEX_EXPORT_BEGIN\r?\n(.*?)\r?\nVORTEX_EXPORT_END')
    if (-not $match.Success) { throw 'Missing Designer export' }
    $output | Where-Object { $_ -like 'PASS:*' } | Write-Output
    $generated = $match.Groups[1].Value
    [System.IO.File]::WriteAllText($exportPath, $generated)
    & $Compiler --null $exportPath
    if ($LASTEXITCODE -ne 0) { throw 'Generated Lua compilation failed' }
    $mock = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'RobloxMock.luau')
    $generated = [regex]::Replace($generated, '^local Library = [^\r\n]+', "local Library = newLibrary()")
    $execution = "$mock`nlocal function newLibrary()`n$librarySource`nend`nlocal exported = (function()`n$generated`nend)()`nassert(exported.Window and exported.Toggles.Enabled, 'Exported controls missing')`nexported:Unload()`nprint('PASS: Generated Designer Lua executes')"
    [System.IO.File]::WriteAllText($exportPath, $execution)
    & $Luau $exportPath
    if ($LASTEXITCODE -ne 0) { throw 'Generated Lua execution failed' }
} finally {
    if (Test-Path -LiteralPath $runnerPath) { Remove-Item -LiteralPath $runnerPath }
    if (Test-Path -LiteralPath $exportPath) { Remove-Item -LiteralPath $exportPath }
}
