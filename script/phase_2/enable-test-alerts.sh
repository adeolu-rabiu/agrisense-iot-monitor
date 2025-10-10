#!/usr/bin/env bash
# Enable Phase 2 test mode: short 'for:' + FORCE_* flags
set -euo pipefail

# 1) Ensure prom can hot-reload; if not present, we still restart below
if ! docker inspect prometheus | grep -q -- '--web.enable-lifecycle'; then
  echo "ℹ️  Consider adding --web.enable-lifecycle to Prometheus command for hot reloads."
fi

# 2) Backup and write short test rules
mkdir -p prometheus/rules
cp -n prometheus/rules/base.yml prometheus/rules/base.yml.bak || true

cat > prometheus/rules/test-short.yml <<'YAML'
groups:
  - name: agrisense_device_alerts_test
    interval: 5s
    rules:
      - alert: LowSignalStrength
        expr: signal_strength_dbm < -90
        for: 15s
        labels: { severity: warning, component: connectivity }
        annotations:
          summary: "Low signal strength (TEST)"
          description: "Device {{ $labels.silo_id }} signal {{ $value }} dBm"

      - alert: CriticalBattery
        expr: battery_level_percent < 20
        for: 15s
        labels: { severity: critical, component: power }
        annotations:
          summary: "Critical battery (TEST)"
          description: "Device {{ $labels.silo_id }} battery {{ $value }}%"

      - alert: SensorDropout
        expr: rate(sensor_dropout_total[1m]) > 0.05
        for: 15s
        labels: { severity: critical, component: sensor }
        annotations:
          summary: "Sensor dropout (TEST)"
          description: "Silo {{ $labels.silo_id }} experiencing sensor failures"
YAML

# 3) Force simulator states via .env
cp -n .env .env.bak || true
if grep -q '^SIMULATOR_FORCE_LOW_BATTERY=' .env; then
  sed -i 's/^SIMULATOR_FORCE_LOW_BATTERY=.*/SIMULATOR_FORCE_LOW_BATTERY=true/' .env
else
  echo 'SIMULATOR_FORCE_LOW_BATTERY=true' >> .env
fi
if grep -q '^SIMULATOR_FORCE_LOW_SIGNAL=' .env; then
  sed -i 's/^SIMULATOR_FORCE_LOW_SIGNAL=.*/SIMULATOR_FORCE_LOW_SIGNAL=true/' .env
else
  echo 'SIMULATOR_FORCE_LOW_SIGNAL=true' >> .env
fi
if grep -q '^SIMULATOR_FORCE_DROPOUT=' .env; then
  sed -i 's/^SIMULATOR_FORCE_DROPOUT=.*/SIMULATOR_FORCE_DROPOUT=true/' .env
else
  echo 'SIMULATOR_FORCE_DROPOUT=true' >> .env
fi

# 4) Reload Prometheus (or restart)
if curl -fsS -X POST http://localhost:9090/-/reload >/dev/null 2>&1; then
  echo "Prometheus reloaded"
else
  echo "Reload not enabled; restarting Prometheus..."
  docker compose restart prometheus
fi

# 5) Restart simulator to apply FORCE flags
docker compose restart device-simulator

echo "✅ Test mode enabled. Re-run: bash script/phase_2/verify-phase2.sh"

