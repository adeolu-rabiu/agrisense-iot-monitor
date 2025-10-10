#!/usr/bin/env bash
# Subscribe to simulator telemetry
# Usage: bash script/phase_2/mqtt-telemetry-tail.sh [host]
set -euo pipefail
HOST="${1:-localhost}"
if ! command -v mosquitto_sub >/dev/null; then
  echo "Install mosquitto-clients first (sudo apt -y install mosquitto-clients)"
  exit 2
fi
echo "Listening on mqtt://$HOST:1883 topic agrisense/+/telemetry ..."
mosquitto_sub -h "$HOST" -t 'agrisense/+/telemetry' -v

