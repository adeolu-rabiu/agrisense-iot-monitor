#!/usr/bin/env bash
# ==========================================================
# AgriSense IoT Monitor - Phase 2 Verifier
# Verifies device simulator → MQTT → Prometheus scrape → alerts
# Usage:
#   bash script/phase_2/verify-phase2.sh
#   bash script/phase_2/verify-phase2.sh --install-deps
# ==========================================================
set -euo pipefail

LOG_DIR="${LOG_DIR:-./logs}"
mkdir -p "$LOG_DIR"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
LOGFILE="$LOG_DIR/verify-phase2-$RUN_ID.log"
exec > >(tee -a "$LOGFILE") 2>&1

PROM_URL="${PROM_URL:-http://localhost:9090}"
SIM_PORT="${SIMULATOR_SCRAPE_PORT:-8081}"
MQTT_HOST="${MQTT_HOST:-localhost}"

# Defaults if .env missing
SIM_FORCE_BAT=false
SIM_FORCE_SIG=false
SIM_FORCE_DROP=false

if [[ -f .env ]]; then
  # shellcheck disable=SC2046
  export $(grep -E '^(SIMULATOR_SCRAPE_PORT|SIMULATOR_FORCE_LOW_BATTERY|SIMULATOR_FORCE_LOW_SIGNAL|SIMULATOR_FORCE_DROPOUT)=' .env | xargs -d '\n' -I {} echo {})
  SIM_PORT="${SIMULATOR_SCRAPE_PORT:-$SIM_PORT}"
  SIM_FORCE_BAT="${SIMULATOR_FORCE_LOW_BATTERY:-false}"
  SIM_FORCE_SIG="${SIMULATOR_FORCE_LOW_SIGNAL:-false}"
  SIM_FORCE_DROP="${SIMULATOR_FORCE_DROPOUT:-false}"
fi

if [[ "${1:-}" == "--install-deps" ]]; then
  sudo apt-get update -y
  sudo apt-get install -y curl jq mosquitto-clients
fi

have(){ command -v "$1" >/dev/null 2>&1; }
need(){ for c in "$@"; do have "$c" || { echo "Missing $c"; exit 2; }; done; }
need curl jq docker

PASS=0; FAIL=0
pass(){ echo "✅ $1"; PASS=$((PASS+1)); }
fail(){ echo "❌ $1"; FAIL=$((FAIL+1)); }

echo "=== Phase 2 Verification started $(date) ==="
echo "PROM_URL=$PROM_URL  SIM_PORT=$SIM_PORT  MQTT_HOST=$MQTT_HOST"
echo "FORCE flags: battery=$SIM_FORCE_BAT signal=$SIM_FORCE_SIG dropout=$SIM_FORCE_DROP"
echo

# 1) Containers present
if docker compose ps | grep -q device-simulator; then
  pass "device-simulator container is present"
else
  fail "device-simulator service missing — did you add it to docker-compose.yml?"
fi

# 2) Simulator metrics endpoint
if curl -fsS "http://localhost:${SIM_PORT}/metrics" | grep -q 'device_weight_kg'; then
  pass "Simulator metrics endpoint is serving expected metrics"
else
  fail "Simulator metrics missing on :${SIM_PORT}/metrics"
fi

# 3) Prometheus target UP
TARGETS=$(curl -fsS "$PROM_URL/api/v1/targets" | jq -r '.data.activeTargets[] | "\(.labels.job) \(.health) \(.scrapeUrl)"' || true)
echo "$TARGETS" | sed -n '1,20p'
if echo "$TARGETS" | grep -q 'agrisense-simulator up'; then
  pass "Prometheus target 'agrisense-simulator' is UP"
else
  fail "Prometheus not scraping simulator (target not UP)"
fi

# 4) Metric names & sample series
NAMES=$(curl -fsS "$PROM_URL/api/v1/label/__name__/values" | jq -r '.data[]' || true)
for m in device_weight_kg signal_strength_dbm battery_level_percent sensor_dropout_total; do
  if echo "$NAMES" | grep -qx "$m"; then pass "Metric '$m' present"; else fail "Metric '$m' missing"; fi
done

# Check one labeled series exists
if curl -fsS "$PROM_URL/api/v1/series?match[]=battery_level_percent" | jq -e '.data[0].silo_id' >/dev/null 2>&1; then
  pass "Metrics include expected label 'silo_id'"
else
  fail "No series with label 'silo_id' found"
fi

# 5) MQTT telemetry messages live
if have mosquitto_sub && have mosquitto_pub; then
  TMP="$(mktemp)"
  ( timeout 10s mosquitto_sub -h "$MQTT_HOST" -t 'agrisense/+/telemetry' -C 1 -v >"$TMP" 2>/dev/null ) &
  # give it a moment and publish a simulator-style message to ensure we catch one
  sleep 1
  mosquitto_pub -h "$MQTT_HOST" -t "agrisense/TestSilo/telemetry" -m '{"hello":"world"}' || true
  sleep 1
  if [[ -s "$TMP" ]]; then
    echo "MQTT sample:"; cat "$TMP"
    pass "MQTT topic agrisense/+/telemetry receiving messages"
  else
    fail "MQTT telemetry not observed — check simulator logs or broker"
  fi
  rm -f "$TMP"
else
  fail "mosquitto-clients not installed; run with --install-deps"
fi

# 6) Alerts — presence of device rules group
RULE_GROUPS=$(curl -fsS "$PROM_URL/api/v1/rules" | jq -r '.data.groups[].name' || true)
if echo "$RULE_GROUPS" | grep -q 'agrisense_device_alerts'; then
  pass "Rule group 'agrisense_device_alerts' loaded"
else
  fail "Rule group 'agrisense_device_alerts' NOT loaded"
fi

# 7) Alerts — FIRE using test mode (short rules + FORCE flags)
ALERTS_JSON="$(curl -fsS "$PROM_URL/api/v1/alerts" | jq -r '.data.alerts[].labels.alertname' || true)"
echo "Current alerts: $ALERTS_JSON"

if [[ "$SIM_FORCE_BAT" == "true" || "$SIM_FORCE_SIG" == "true" || "$SIM_FORCE_DROP" == "true" ]]; then
  echo "Test mode detected (FORCE flags true). Checking for expected alerts after short 'for:'..."
  sleep 20
  ALERTS_JSON="$(curl -fsS "$PROM_URL/api/v1/alerts" | jq -r '.data.alerts[].labels.alertname' || true)"
  EXPECT=(CriticalBattery LowSignalStrength SensorDropout)
  for a in "${EXPECT[@]}"; do
    if echo "$ALERTS_JSON" | grep -q "$a"; then pass "Alert FIRING: $a"; else echo "ℹ️  $a not firing yet"; fi
  done
else
  echo "ℹ️  Test alerts not forced; run 'bash script/phase_2/enable-test-alerts.sh' then re-run verifier."
fi

echo
echo "=== Phase 2 Verification Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Log:    $LOGFILE"
echo
[[ $FAIL -eq 0 ]] && { echo "🎯 PHASE 2 VERIFIED"; exit 0; } || { echo "⚠️  PHASE 2 ISSUES FOUND"; exit 1; }

