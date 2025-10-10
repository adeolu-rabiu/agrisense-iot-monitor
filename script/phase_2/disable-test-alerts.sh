#!/usr/bin/env bash
# Disable Phase 2 test mode (restore defaults)
set -euo pipefail

rm -f prometheus/rules/test-short.yml || true

# Turn off FORCE flags in .env (keep keys for clarity)
if [[ -f .env ]]; then
  sed -i 's/^SIMULATOR_FORCE_LOW_BATTERY=.*/SIMULATOR_FORCE_LOW_BATTERY=false/' .env || true
  sed -i 's/^SIMULATOR_FORCE_LOW_SIGNAL=.*/SIMULATOR_FORCE_LOW_SIGNAL=false/' .env || true
  sed -i 's/^SIMULATOR_FORCE_DROPOUT=.*/SIMULATOR_FORCE_DROPOUT=false/' .env || true
fi

# Reload Prometheus (or restart)
if curl -fsS -X POST http://localhost:9090/-/reload >/dev/null 2>&1; then
  echo "Prometheus reloaded"
else
  docker compose restart prometheus
fi

docker compose restart device-simulator
echo "✅ Test mode disabled."

