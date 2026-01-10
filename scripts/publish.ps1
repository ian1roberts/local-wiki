$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location (Join-Path $root "src")

if (Test-Path "..\site") { Remove-Item "..\site" -Recurse -Force }
New-Item "..\site" -ItemType Directory | Out-Null

quarto render . --no-execute

Set-Location $root
git add -A

$msg = Read-Host "Commit message"
if ([string]::IsNullOrWhiteSpace($msg)) { $msg = "publish" }

try { git commit -m $msg } catch { Write-Host "No changes to commit" }
git push pi main
