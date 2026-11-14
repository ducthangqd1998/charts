#!/usr/bin/env bash
# Test script for the metrics-accumulator Helm chart.
# Runs static lint and template checks by default; pass --live to run cluster integration tests.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_NAME="metrics-accumulator"
RELEASE_NAME="${RELEASE_NAME:-test-metrics-accumulator}"
NAMESPACE="${NAMESPACE:-default}"
LIVE_TEST=false

for arg in "$@"; do
  case "$arg" in
    --live)
      LIVE_TEST=true
      ;;
    *)
      echo "Usage: $0 [--live]" >&2
      exit 1
      ;;
  esac
done

echo "Testing Helm Chart: ${CHART_NAME} (${CHART_DIR})"

echo "Step 1: Linting chart with default values..."
helm lint "${CHART_DIR}"

echo "Step 2: Linting and rendering default values..."
helm template "${RELEASE_NAME}" "${CHART_DIR}" --namespace "${NAMESPACE}" > /dev/null

echo "Step 3: Linting and rendering development values..."
helm lint "${CHART_DIR}" --values "${CHART_DIR}/examples/development-values.yaml"
helm template "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --values "${CHART_DIR}/examples/development-values.yaml" > /dev/null

echo "Step 4: Linting and rendering production values..."
helm lint "${CHART_DIR}" --values "${CHART_DIR}/examples/production-values.yaml"
helm template "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --values "${CHART_DIR}/examples/production-values.yaml" > /dev/null

if [ "${LIVE_TEST}" != "true" ]; then
  echo "Static chart validation completed successfully (pass --live to run cluster smoke tests)."
  exit 0
fi

cleanup() {
  echo "Cleaning up test release ${RELEASE_NAME} in namespace ${NAMESPACE}..."
  helm uninstall "${RELEASE_NAME}" --namespace "${NAMESPACE}" 2>/dev/null || true
}
trap cleanup EXIT

echo "Step 5: Installing chart for live smoke test..."
helm install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --wait \
  --timeout=300s

echo "Step 6: Waiting for pod readiness..."
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/name=${CHART_NAME},app.kubernetes.io/instance=${RELEASE_NAME}" \
  --namespace "${NAMESPACE}" \
  --timeout=120s

POD_NAME="$(kubectl get pods --namespace "${NAMESPACE}" \
  -l "app.kubernetes.io/name=${CHART_NAME},app.kubernetes.io/instance=${RELEASE_NAME}" \
  -o jsonpath="{.items[0].metadata.name}")"

echo "Step 7: Verifying upstream HTTP endpoints (/service-discovery and /metrics/default)..."
kubectl exec "${POD_NAME}" --namespace "${NAMESPACE}" -- \
  wget -q -O- "http://127.0.0.1:8080/service-discovery" > /dev/null
kubectl exec "${POD_NAME}" --namespace "${NAMESPACE}" -- \
  wget -q -O- "http://127.0.0.1:8080/metrics/default" > /dev/null

echo "All static and live tests completed successfully!"
