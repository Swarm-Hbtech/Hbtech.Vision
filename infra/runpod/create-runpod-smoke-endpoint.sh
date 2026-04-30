#!/usr/bin/env bash
set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required"
  exit 1
fi

RUNPOD_API_KEY="${RUNPOD_API_KEY:-}"
IMAGE_NAME="${IMAGE_NAME:-docker.io/swarmhbtech/runpod-smoke-worker:v1}"

TEMPLATE_NAME="${TEMPLATE_NAME:-swarm-runpod-smoke-worker-v1}"
ENDPOINT_NAME="${ENDPOINT_NAME:-swarm-smoke-endpoint-v1}"

CONTAINER_DISK_GB="${CONTAINER_DISK_GB:-5}"
IDLE_TIMEOUT="${IDLE_TIMEOUT:-5}"
EXECUTION_TIMEOUT_MS="${EXECUTION_TIMEOUT_MS:-120000}"
WORKERS_MIN="${WORKERS_MIN:-0}"
WORKERS_MAX="${WORKERS_MAX:-1}"
GPU_COUNT="${GPU_COUNT:-1}"

TEMPLATE_FILE="${TEMPLATE_FILE:-create-template.json}"
ENDPOINT_FILE="${ENDPOINT_FILE:-create-endpoint.json}"
TEMPLATE_RESPONSE_FILE="${TEMPLATE_RESPONSE_FILE:-template-response.json}"
ENDPOINT_RESPONSE_FILE="${ENDPOINT_RESPONSE_FILE:-endpoint-response.json}"

if [[ -z "${RUNPOD_API_KEY}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is not set"
  exit 1
fi

echo "==> Creating RunPod smoke-test template + endpoint"
echo "Image: ${IMAGE_NAME}"
echo "Template name: ${TEMPLATE_NAME}"
echo "Endpoint name: ${ENDPOINT_NAME}"
echo

cat > "${TEMPLATE_FILE}" <<JSON
{
  "name": "${TEMPLATE_NAME}",
  "imageName": "${IMAGE_NAME}",
  "isServerless": true,
  "category": "NVIDIA",
  "containerDiskInGb": ${CONTAINER_DISK_GB},
  "volumeInGb": 0,
  "volumeMountPath": "/workspace",
  "env": {}
}
JSON

echo "==> Template payload written to ${TEMPLATE_FILE}"
cat "${TEMPLATE_FILE}"
echo

echo "==> Creating template..."
curl -sS -X POST "https://rest.runpod.io/v1/templates" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @"${TEMPLATE_FILE}" > "${TEMPLATE_RESPONSE_FILE}"

echo "==> Template response saved to ${TEMPLATE_RESPONSE_FILE}"
cat "${TEMPLATE_RESPONSE_FILE}" | python3 -m json.tool
echo

TEMPLATE_ID="$(python3 - <<'PY' "${TEMPLATE_RESPONSE_FILE}"
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
print(data.get("id", ""))
PY
)"

if [[ -z "${TEMPLATE_ID}" ]]; then
  echo "ERROR: Could not extract template id"
  exit 1
fi

echo "==> Template ID: ${TEMPLATE_ID}"
echo

cat > "${ENDPOINT_FILE}" <<JSON
{
  "name": "${ENDPOINT_NAME}",
  "templateId": "${TEMPLATE_ID}",
  "computeType": "GPU",
  "gpuCount": ${GPU_COUNT},
  "gpuTypeIds": [
    "NVIDIA GeForce RTX 3090",
    "NVIDIA RTX A4000",
    "NVIDIA RTX 4000 Ada Generation",
    "NVIDIA A40"
  ],
  "workersMin": ${WORKERS_MIN},
  "workersMax": ${WORKERS_MAX},
  "idleTimeout": ${IDLE_TIMEOUT},
  "executionTimeoutMs": ${EXECUTION_TIMEOUT_MS},
  "scalerType": "QUEUE_DELAY",
  "scalerValue": 4
}
JSON

echo "==> Endpoint payload written to ${ENDPOINT_FILE}"
cat "${ENDPOINT_FILE}"
echo

echo "==> Creating endpoint..."
curl -sS -X POST "https://rest.runpod.io/v1/endpoints" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d @"${ENDPOINT_FILE}" > "${ENDPOINT_RESPONSE_FILE}"

echo "==> Endpoint response saved to ${ENDPOINT_RESPONSE_FILE}"
cat "${ENDPOINT_RESPONSE_FILE}" | python3 -m json.tool
echo

ENDPOINT_ID="$(python3 - <<'PY' "${ENDPOINT_RESPONSE_FILE}"
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
print(data.get("id", ""))
PY
)"

if [[ -z "${ENDPOINT_ID}" ]]; then
  echo "ERROR: Could not extract endpoint id"
  exit 1
fi

echo "==> Endpoint ID: ${ENDPOINT_ID}"
echo

echo "============================================================"
echo "RunPod smoke endpoint created successfully"
echo "============================================================"
echo "export RUNPOD_API_KEY='${RUNPOD_API_KEY}'"
echo "export RUNPOD_ENDPOINT_ID='${ENDPOINT_ID}'"
echo
echo "Then run:"
echo "./test-runpod-endpoint.sh"
echo
echo "Optional runsync:"
echo "RUNPOD_MODE=runsync ./test-runpod-endpoint.sh"
