#!/usr/bin/env bash
set -euo pipefail

# Load environment variables from .env file
if [ -f .env ]; then
  # Export all variables from .env, ignoring comments and empty lines
  export $(grep -v '^#' .env | grep -v '^$' | xargs)
else
  echo "❌ .env file not found!"
  exit 1
fi

# Verify required credentials are set
if [ -z "${GF_SECURITY_ADMIN_USER:-}" ] || [ -z "${GF_SECURITY_ADMIN_PASSWORD:-}" ]; then
  echo "❌ GF_SECURITY_ADMIN_USER or GF_SECURITY_ADMIN_PASSWORD not set in .env"
  exit 1
fi

PROM=http://localhost:9090
GRAF=http://localhost:3000
GUSER="$GF_SECURITY_ADMIN_USER"
GPASS="$GF_SECURITY_ADMIN_PASSWORD"

pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; exit 1; }

echo "=== Phase 3 Verification ==="

# Check recording rules
curl -fsS "$PROM/api/v1/rules" | jq -r '.data.groups[].name' | grep -q agrisense_recording \
  && pass "Recording rules loaded" || fail "Recording rules missing"

# Check specific queries
for Q in 'agrisense:fleet_battery_min' 'agrisense:fleet_weight_sum' 'agrisense:sensor_dropout_rate:5m'; do
  curl -fsS "$PROM/api/v1/query?query=$Q" >/dev/null && pass "Query OK: $Q" || fail "Query failed: $Q"
done

# Check Grafana health
curl -fsS "$GRAF/api/health" | jq -e '.database=="ok"' >/dev/null \
  && pass "Grafana healthy" || fail "Grafana not healthy"

# Check dashboard exists
curl -fsS -u "$GUSER:$GPASS" "$GRAF/api/dashboards/uid/agri-overview" \
 | jq -e '.dashboard.uid=="agri-overview"' >/dev/null \
  && pass "Dashboard present: Agrisense — Overview" || fail "Dashboard not found"

echo "🎯 Phase 3 verified"
