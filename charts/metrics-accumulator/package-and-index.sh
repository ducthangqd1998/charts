#!/bin/bash

# Script to package and update Helm repo index for metrics-accumulator
# This script will NOT be tracked by git (see .gitignore)

set -e

CHART_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_NAME="metrics-accumulator"
REPO_URL="https://ducthangqd1998.github.io/charts/metrics-accumulator"

cd "$CHART_DIR"

# Package the chart
helm package .

# Update or create the index.yaml for the repo
helm repo index . --url "$REPO_URL"

echo "✅ Chart packaged and index updated!"
echo "📦 Chart package: $(ls ${CHART_NAME}-*.tgz | tail -n1)"
echo "🗂  Repo index: $CHART_DIR/index.yaml" 