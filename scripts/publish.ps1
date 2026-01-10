$ErrorActionPreference = "Stop"

# Always run from repo root
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

# --- Inject deploy metadata for the footer ---
$Commit = (git rev-parse --short HEAD).Trim()
$Date   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

@"
commit: "$Commit"
date: "$Date"
"@ | Set-Content -Encoding UTF8 .\src\_deploy.yml

# Render Quarto project in src/ (output-dir: site -> src/site/)
quarto render .\src --no-execute

# Sanity check
if (!(Test-Path ".\src\site\index.html")) {
  throw "src\site\index.html not found. Render failed or output-dir is wrong."
}

# Commit ONLY rendered output (and the metadata file, so footer matches)
git add -A .\src\site .\src\_deploy.yml

$Msg = $args[0]
if (-not $Msg) { $Msg = "Publish" }

if (git status --porcelain) {
  git commit -m $Msg
  git push pi main
} else {
  Write-Host "No changes to commit; nothing pushed."
}
