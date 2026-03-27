#!/usr/bin/env bash
# prahari_lite_commit.sh
# Auto-commit PRAHARI-Lite experiment outputs
# Usage: ./prahari_lite_commit.sh "commit message"
# Safety: never touches ../docker_env/

set -euo pipefail

PRAHARI_LITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PRAHARI_LITE_DIR"

echo "================================================="
echo "PRAHARI-Lite Commit Script"
echo "Working dir: $PRAHARI_LITE_DIR"
echo "================================================="

# Safety check: ensure we are NOT in docker_env
if [[ "$PRAHARI_LITE_DIR" == *"docker_env"* ]]; then
    echo "ERROR: This script must not be run from docker_env!"
    exit 1
fi

# Git status
echo ""
echo "=== Git Status ==="
git status --short

# Stage relevant files (never models/*.pkl or outputs/*.png)
git add \
    training/ \
    experiments/ \
    runtime/ \
    dashboard/ \
    fpga/ \
    docs/*.md \
    docs/*.json \
    models/*.csv \
    outputs/*.csv \
    outputs/*.json \
    requirements_lite.txt \
    docker-compose-lite.yml \
    Dockerfile.lite \
    .gitignore \
    README.md 2>/dev/null || true

echo ""
echo "=== Staged Files ==="
git diff --cached --name-only

# Commit message
MSG="${1:-PRAHARI-Lite: auto-commit experiment outputs}"

echo ""
echo "=== Committing ==="
git commit -m "$MSG

System: PRAHARI-Lite (DT + AE fusion)
Isolated from PRAHARI v7 at ../docker_env/
Novel: DT leaf purity as zero-day confidence gate
Ports: API=5001, Dashboard=5002" || echo "Nothing to commit"

echo ""
echo "=== Done ==="
git log --oneline -5
