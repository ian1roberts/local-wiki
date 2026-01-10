#!/usr/bin/env bash
set -euo pipefail

# Always run from repo root
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# --- Inject deploy metadata for the footer ---
COMMIT=$(git rev-parse --short HEAD)
DATE=$(date "+%Y-%m-%d %H:%M:%S")

cat > ./src/_deploy.yml <<EOF
commit: "$COMMIT"
date: "$DATE"
EOF

# Render Quarto project in src/ (output-dir: site -> src/site/)
quarto render ./src --no-execute

# Sanity check
if [[ ! -f "./src/site/index.html" ]]; then
  echo "Error: src/site/index.html not found. Render failed or output-dir is wrong."
  exit 1
fi

# Commit ONLY rendered output (and the metadata file, so footer matches)
git add -A ./src/site ./src/_deploy.yml

MSG="${1:-Publish}"

if [[ -n $(git status --porcelain) ]]; then
  git commit -m "$MSG"
  git push pi main
else
  echo "No changes to commit; nothing pushed."
fi
