#!/bin/bash

# Auto-deploy script for metrics-accumulator Helm chart
# This script will NOT be tracked by git (see .gitignore)

set -e

CHART_DIR="$(cd "$(dirname "$0")" && pwd)"
CHART_NAME="metrics-accumulator"
DEFAULT_RELEASE="metrics-accumulator"
DEFAULT_NAMESPACE="default"

read -p "Enter release name [default: $DEFAULT_RELEASE]: " RELEASE
RELEASE=${RELEASE:-$DEFAULT_RELEASE}

read -p "Enter chart version (e.g. 1.2.3): " VERSION
if [[ -z "$VERSION" ]]; then
  echo "❌ Version is required!"
  exit 1
fi

read -p "Enter namespace [default: $DEFAULT_NAMESPACE]: " NAMESPACE
NAMESPACE=${NAMESPACE:-$DEFAULT_NAMESPACE}

# Optional: choose values file
if [ -f "$CHART_DIR/examples/production-values.yaml" ]; then
  read -p "Use production values? [y/N]: " USE_PROD
  if [[ "$USE_PROD" =~ ^[Yy]$ ]]; then
    VALUES_ARG="-f $CHART_DIR/examples/production-values.yaml"
  else
    VALUES_ARG=""
  fi
else
  VALUES_ARG=""
fi

echo "🚀 Deploying $RELEASE version $VERSION to namespace $NAMESPACE..."

helm upgrade --install "$RELEASE" "$CHART_DIR" \
  --namespace "$NAMESPACE" \
  --set image.tag="$VERSION" \
  $VALUES_ARG \
  --wait

echo "✅ Done! Use 'kubectl get all -l app.kubernetes.io/instance=$RELEASE -n $NAMESPACE' to check resources." 