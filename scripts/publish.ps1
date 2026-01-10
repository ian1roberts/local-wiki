$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

# 1) Inject deploy metadata for footer (stored in src/)
$Commit = (git rev-parse --short HEAD).Trim()
$Date   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

$deployText = @"
commit: "$Commit"
date: "$Date"
"@

[System.IO.File]::WriteAllText(
  (Join-Path $RepoRoot "src\_deploy.yml"),
  $deployText,
  (New-Object System.Text.UTF8Encoding($false))  # $false = no BOM
)


# 2) Render locally (frozen)
quarto render .\src --no-execute
if (!(Test-Path ".\src\site\index.html")) {
  throw "Render failed: src\site\index.html not found."
}

# 3) Commit/push SOURCES (main) to GitHub
git add -A .\src .\scripts .\.vscode .\README.md 2>$null
# (Adjust what you want tracked on main; src/site should be ignored now)
$Msg = $args[0]
if (-not $Msg) { $Msg = "Publish" }

if (git status --porcelain) {
  git commit -m $Msg
}
git push origin main

# 4) Update deploy worktree from rendered output
if (!(Test-Path ".\.deploy")) {
  git worktree add -B deploy .deploy
}

Remove-Item -Recurse -Force .\.deploy\* -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force .\src\site\* .\.deploy\

Push-Location .\.deploy
git add -A
if (git status --porcelain) {
  git commit -m "Deploy $Msg"
}
git push pi deploy
Pop-Location
