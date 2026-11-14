param([string]$Flutter = "flutter", [string]$Python = "python", [string]$RunId = "")
$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $RunId) { $RunId = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ") + "-$PID" }
if ($RunId -notmatch '^[a-zA-Z0-9_-]+$') { throw "RunId inválido." }
$outputDir = Join-Path $repoRoot "evidencias/ejecuciones/$RunId"
if (Test-Path -LiteralPath $outputDir) { throw "No sobrescribir una ejecución existente." }
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
$startedUtc = (Get-Date).ToUniversalTime().ToString("o")
$commit = (& git -C $repoRoot rev-parse HEAD 2>$null)
$dirty = [bool](& git -C $repoRoot status --porcelain)
$flutterVersion = (& $Flutter --version | Select-Object -First 1)
$metadata = [ordered]@{ run_id=$RunId; started_utc=$startedUtc; commit="$commit"; dirty=$dirty; os=[Environment]::OSVersion.VersionString; flutter="$flutterVersion" }
Push-Location (Join-Path $repoRoot "app")
try {
    & $Flutter pub get *> (Join-Path $outputDir "pub.log")
    $metadata.pub_exit = $LASTEXITCODE
    $flutterExecutable = Get-Command $Flutter -ErrorAction Stop
    $sdkBin = Split-Path -Parent $flutterExecutable.Source
    $dart = Join-Path $sdkBin "dart.bat"
    if (-not (Test-Path -LiteralPath $dart)) { $dart = "dart" }
    & $dart format --output=none --set-exit-if-changed lib test *> (Join-Path $outputDir "format.log")
    $metadata.format_exit = $LASTEXITCODE
    & $Flutter analyze --no-pub *> (Join-Path $outputDir "analyze.log")
    $metadata.analyze_exit = $LASTEXITCODE
    $coverageFile = Join-Path $repoRoot "app/coverage/lcov.info"
    if (Test-Path -LiteralPath $coverageFile) { Remove-Item -LiteralPath $coverageFile }
    & $Flutter test --no-pub --coverage --machine *> (Join-Path $outputDir "tests.jsonl")
    $metadata.test_exit = $LASTEXITCODE
    if (Test-Path -LiteralPath $coverageFile) { Copy-Item -LiteralPath $coverageFile -Destination (Join-Path $outputDir "lcov.info") }
} finally {
    Pop-Location
    $metadata | ConvertTo-Json | Set-Content -Encoding utf8 (Join-Path $outputDir "metadata.json")
}
& $Python (Join-Path $PSScriptRoot "report.py") $outputDir
$reportExit = $LASTEXITCODE
Write-Output "Evidencia: $outputDir"
exit $reportExit
