$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$codexRoot = Join-Path $repoRoot "plugins/psych-network-css"
$claudeRoot = Join-Path $repoRoot "plugins/psych-network-analysis"

$assetNames = @("network_analysis_template.R", "network_comparison_tutorial.R", "clpn_tutorial.R")
$referenceSource = Join-Path $codexRoot "references"
$referenceTarget = Join-Path $claudeRoot "references"

foreach ($path in @($referenceSource, $codexRoot, $claudeRoot)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "Required path not found: $path"
  }
}

New-Item -ItemType Directory -Force -Path (Join-Path $claudeRoot "assets"), $referenceTarget | Out-Null
foreach ($assetName in $assetNames) {
  $assetSource = Join-Path $codexRoot "assets/$assetName"
  if (-not (Test-Path -LiteralPath $assetSource)) {
    throw "Required shared tutorial not found: $assetSource"
  }
  Copy-Item -LiteralPath $assetSource -Destination (Join-Path $claudeRoot "assets/$assetName") -Force
}
Get-ChildItem -LiteralPath $referenceSource -File | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $referenceTarget $_.Name) -Force
}

foreach ($skillName in @("analyze-cross-lagged-panel-network", "compare-cross-sectional-networks")) {
  $skillSource = Join-Path $codexRoot "skills/$skillName/SKILL.md"
  $skillTarget = Join-Path $claudeRoot "skills/$skillName/SKILL.md"
  if (-not (Test-Path -LiteralPath $skillSource) -or -not (Test-Path -LiteralPath $skillTarget)) {
    throw "Required skill file not found for synchronization: $skillName"
  }
  Copy-Item -LiteralPath $skillSource -Destination $skillTarget -Force
}

Write-Host "Synchronized shared templates, reporting references, and matching skills from Codex to Claude."
