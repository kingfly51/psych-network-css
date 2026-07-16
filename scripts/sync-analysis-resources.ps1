$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$claudeRoot = Join-Path $repoRoot "plugins/psych-network-analysis"
$codexRoot = Join-Path $repoRoot "plugins/psych-network-css"

$assetSource = Join-Path $claudeRoot "assets/network_analysis_template.R"
$assetTarget = Join-Path $codexRoot "assets/network_analysis_template.R"
$referenceSource = Join-Path $claudeRoot "references"
$referenceTarget = Join-Path $codexRoot "references"

foreach ($path in @($assetSource, $referenceSource, $codexRoot)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required path not found: $path"
  }
}

New-Item -ItemType Directory -Force -Path (Split-Path $assetTarget), $referenceTarget | Out-Null
Copy-Item -LiteralPath $assetSource -Destination $assetTarget -Force
Get-ChildItem -LiteralPath $referenceSource -File | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $referenceTarget $_.Name) -Force
}

Write-Host "Synchronized R template and methodology references from Claude to Codex."
