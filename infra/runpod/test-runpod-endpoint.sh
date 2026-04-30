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
RUNPOD_ENDPOINT_ID="${RUNPOD_ENDPOINT_ID:-}"
RUNPOD_MODE="${RUNPOD_MODE:-run}"
SLEEP_SECONDS="${SLEEP_SECONDS:-2}"
POLL_INTERVAL="${POLL_INTERVAL:-2}"
MAX_POLLS="${MAX_POLLS:-90}"

if [[ -z "${RUNPOD_API_KEY}" ]]; then
  echo "ERROR: RUNPOD_API_KEY is not set"
  exit 1
fi

if [[ -z "${RUNPOD_ENDPOINT_ID}" ]]; then
  echo "ERROR: RUNPOD_ENDPOINT_ID is not set"
  exit 1
fi

BASE_URL="https://api.runpod.ai/v2/${RUNPOD_ENDPOINT_ID}"
REQUEST_URL="${BASE_URL}/${RUNPOD_MODE}"

REQUEST_JSON="$(cat <<JSON
{
  "input": {
    "label": "first-smoke-test",
    "sleep_seconds": ${SLEEP_SECONDS},
    "echo": {
      "source": "moscow",
      "purpose": "runpod-platform-baseline"
    }
  }
}
JSON
)"

echo "==> RunPod endpoint test"
echo "Endpoint ID: ${RUNPOD_ENDPOINT_ID}"
echo "Mode: ${RUNPOD_MODE}"
echo "Sleep seconds: ${SLEEP_SECONDS}"
echo "Request URL: ${REQUEST_URL}"
echo

START_TS="$(date +%s)"

if [[ "${RUNPOD_MODE}" == "runsync" ]]; then
  echo "==> Sending runsync request..."
  RESPONSE="$(curl -sS --max-time 600 -X POST "${REQUEST_URL}" \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "${REQUEST_JSON}")"

  END_TS="$(date +%s)"

  echo
  echo "==> Raw response:"
  echo "${RESPONSE}" | python3 -m json.tool

  echo
  echo "==> Summary:"
  RESPONSE_JSON="${RESPONSE}" python3 - "$START_TS" "$END_TS" <<'PY'
import json, os, sys
start_ts = int(sys.argv[1])
end_ts = int(sys.argv[2])
data = json.loads(os.environ['RESPONSE_JSON'])

wall = end_ts - start_ts
print(f"wall_clock_seconds: {wall}")

status = data.get("status", "UNKNOWN")
print(f"status: {status}")

output = data.get("output") or {}
timing = output.get("timing") or {}
print(f"handler_execution_seconds: {timing.get('handler_execution_seconds')}")
print(f"worker_uptime_seconds: {timing.get('worker_uptime_seconds')}")
print(f"sleep_seconds_requested: {timing.get('sleep_seconds_requested')}")
PY

  exit 0
fi

echo "==> Sending queued run request..."
INITIAL_RESPONSE="$(curl -sS --max-time 120 -X POST "${REQUEST_URL}" \
  -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "${REQUEST_JSON}")"

echo
echo "==> Initial response:"
echo "${INITIAL_RESPONSE}" | python3 -m json.tool

JOB_ID="$(INITIAL_RESPONSE_JSON="${INITIAL_RESPONSE}" python3 - <<'PY'
import json, os

data = json.loads(os.environ['INITIAL_RESPONSE_JSON'])
print(data.get("id", ""))
PY
)"

if [[ -z "${JOB_ID}" ]]; then
  echo "ERROR: Could not extract job id from initial response"
  exit 1
fi

echo
echo "==> Job ID: ${JOB_ID}"
echo "==> Polling every ${POLL_INTERVAL}s (max ${MAX_POLLS} polls)"
echo

STATUS_URL="${BASE_URL}/status/${JOB_ID}"

for ((i=1; i<=MAX_POLLS; i++)); do
  NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  STATUS_RESPONSE="$(curl -sS --max-time 120 \
    -H "Authorization: Bearer ${RUNPOD_API_KEY}" \
    "${STATUS_URL}")"

  STATUS="$(STATUS_RESPONSE_JSON="${STATUS_RESPONSE}" python3 - <<'PY'
import json, os

data = json.loads(os.environ['STATUS_RESPONSE_JSON'])
print(data.get("status", "UNKNOWN"))
PY
)"

  echo "[${NOW}] poll=${i} status=${STATUS}"

  if [[ "${STATUS}" == "COMPLETED" ]]; then
    END_TS="$(date +%s)"
    echo
    echo "==> Final response:"
    echo "${STATUS_RESPONSE}" | python3 -m json.tool

    echo
    echo "==> Summary:"
    STATUS_RESPONSE_JSON="${STATUS_RESPONSE}" python3 - "$START_TS" "$END_TS" <<'PY'
import json, os, sys
start_ts = int(sys.argv[1])
end_ts = int(sys.argv[2])
data = json.loads(os.environ['STATUS_RESPONSE_JSON'])

wall = end_ts - start_ts
print(f"wall_clock_seconds: {wall}")
print(f"delayTime: {data.get('delayTime')}")
print(f"executionTime: {data.get('executionTime')}")

output = data.get("output") or {}
timing = output.get("timing") or {}

print(f"handler_execution_seconds: {timing.get('handler_execution_seconds')}")
print(f"worker_uptime_seconds: {timing.get('worker_uptime_seconds')}")
print(f"sleep_seconds_requested: {timing.get('sleep_seconds_requested')}")

if timing.get("handler_execution_seconds") is not None:
    try:
        coldish_overhead = wall - float(timing["handler_execution_seconds"])
        print(f"approx_platform_overhead_seconds: {round(coldish_overhead, 4)}")
    except Exception:
        pass
PY
    exit 0
  fi

  if [[ "${STATUS}" == "FAILED" || "${STATUS}" == "CANCELLED" || "${STATUS}" == "TIMED_OUT" ]]; then
    echo
    echo "==> Terminal failure response:"
    echo "${STATUS_RESPONSE}" | python3 -m json.tool
    exit 2
  fi

  sleep "${POLL_INTERVAL}"
done

echo
echo "ERROR: polling limit exceeded"
exit 3
