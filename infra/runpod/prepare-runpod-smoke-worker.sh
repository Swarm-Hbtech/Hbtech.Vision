#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-swarmhbtech/runpod-smoke-worker}"
IMAGE_TAG="${IMAGE_TAG:-v1}"
PLATFORM="${PLATFORM:-linux/amd64}"
WORKDIR="${WORKDIR:-./runpod-smoke-worker}"

FULL_IMAGE="docker.io/${IMAGE_NAME}:${IMAGE_TAG}"

echo "==> Preparing RunPod smoke worker in: ${WORKDIR}"
mkdir -p "${WORKDIR}"

cat > "${WORKDIR}/handler.py" <<'PY'
import os
import time
import socket
from datetime import datetime, timezone

import runpod

WORKER_BOOT_TIME = time.time()
HOSTNAME = socket.gethostname()


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def handler(event):
    started_at = time.time()

    input_data = event.get("input", {}) or {}
    sleep_seconds = float(input_data.get("sleep_seconds", 2))
    echo = input_data.get("echo", {})
    label = input_data.get("label", "runpod-smoke-test")

    time.sleep(sleep_seconds)

    finished_at = time.time()

    return {
        "ok": True,
        "label": label,
        "echo": echo,
        "timing": {
            "sleep_seconds_requested": sleep_seconds,
            "handler_execution_seconds": round(finished_at - started_at, 4),
            "worker_uptime_seconds": round(finished_at - WORKER_BOOT_TIME, 4)
        },
        "worker": {
            "hostname": HOSTNAME,
            "booted_at_approx_utc": utc_now(),
            "python_env": os.environ.get("PYTHON_VERSION", "unknown")
        },
        "meta": {
            "handled_at_utc": utc_now()
        }
    }


if __name__ == "__main__":
    runpod.serverless.start({"handler": handler})
PY

cat > "${WORKDIR}/requirements.txt" <<'REQ'
runpod==1.7.13
REQ

cat > "${WORKDIR}/Dockerfile" <<'DOCKER'
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHON_VERSION=3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY handler.py .

CMD ["python", "-u", "handler.py"]
DOCKER

echo "==> Files created:"
ls -la "${WORKDIR}"

echo
echo "==> Building image: ${FULL_IMAGE}"
docker build --platform "${PLATFORM}" -t "${FULL_IMAGE}" "${WORKDIR}"

echo
echo "==> Build complete: ${FULL_IMAGE}"
echo

read -r -p "Do you want to docker login now? [y/N] " DO_LOGIN
if [[ "${DO_LOGIN}" =~ ^[Yy]$ ]]; then
  docker login
fi

read -r -p "Do you want to push the image now? [y/N] " DO_PUSH
if [[ "${DO_PUSH}" =~ ^[Yy]$ ]]; then
  docker push "${FULL_IMAGE}"
  echo
  echo "==> Push complete"
fi

echo
echo "Smoke worker image ready:"
echo "  ${FULL_IMAGE}"
echo
echo "Next step:"
echo "  Use this image to create a private RunPod serverless template and a minimal endpoint."
