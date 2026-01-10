$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

# git main guard
if ((git branch --show-current).Trim() -ne "main") {
  throw "Not on main branch in repo root. Aborting."
}

# Commit/push SOURCES (main) to GitHub
git add -A .\src .\scripts .\.vscode .\README.md .\.gitignore 2>$null
# (Adjust what you want tracked on main; src/site should be ignored now)
$Msg = $args[0]
if (-not $Msg) { $Msg = "Publish" }

if (git status --porcelain) {
  git reset -q .deploy 2>$null
  git commit -m $Msg
}

git push origin main

# Inject deploy metadata for footer (stored in src/)
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


# Render locally (frozen)
quarto render .\src --no-execute
if (!(Test-Path ".\src\site\index.html")) {
  throw "Render failed: src\site\index.html not found."
}

# Update deploy worktree from rendered output
# Ensure worktree exists
if (!(Test-Path ".\.deploy\.git")) {
  git worktree add -B deploy .deploy
}

# Safety check
$br = (git -C .\.deploy branch --show-current).Trim()
if ($br -ne "deploy") {
  throw ".deploy is not on deploy branch (got '$br'). Aborting."
}

# Clean deploy folder but NEVER touch .git
Get-ChildItem .\.deploy -Force |
  Where-Object { $_.Name -ne '.git' } |
  Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Copy rendered site into deploy worktree root
Copy-Item -Recurse -Force .\src\site\* .\.deploy\

# Commit + push deploy
git -C .\.deploy add -A
if (git -C .\.deploy status --porcelain) {
  git -C .\.deploy commit -m "Deploy $Msg"
}
git -C .\.deploy push pi deploy
