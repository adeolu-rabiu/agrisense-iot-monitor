🧭 Phase 3 — Grafana Dashboards + Prometheus Recording Rules

This phase provisions a fully automated monitoring dashboard using Prometheus recording rules and Grafana dashboards.
The goal is to eliminate manual UI work — dashboards will appear automatically on startup.

🏷️ Objectives

✅ Create and use Prometheus recording rules for performance and clarity.

✅ Auto-provision Grafana dashboards on container start.

✅ Store everything in Git (no credentials).

✅ Provide a script to verify deployment end-to-end.

🪜 STEP 1 — Add Prometheus Recording Rules

📄 prometheus/rules/recording.yml

groups:
  - name: agrisense_recording
    interval: 30s
    rules:
      # Per-silo friendly series
      - record: agrisense:battery_percent:by_silo
        expr: battery_level_percent
      - record: agrisense:signal_dbm:by_silo
        expr: signal_strength_dbm
      - record: agrisense:weight_kg:by_silo
        expr: device_weight_kg
      - record: agrisense:sensor_dropout_rate:5m
        expr: rate(sensor_dropout_total[5m])

      # Fleet KPIs
      - record: agrisense:fleet_battery_min
        expr: min(battery_level_percent)
      - record: agrisense:fleet_signal_p95
        expr: quantile(0.95, signal_strength_dbm)
      - record: agrisense:fleet_weight_sum
        expr: sum(device_weight_kg)


🌀 Restart Prometheus to load new rules:

docker compose restart prometheus


🧪 Verify rules:

curl -s http://localhost:9090/api/v1/rules | jq -r '.data.groups[].name' | sort
# expected:
# agrisense_device_alerts
# agrisense_recording
# sanity


🧪 Quick metric check:

curl -s 'http://localhost:9090/api/v1/query?query=agrisense%3Afleet_battery_min' | jq '.data.result'
curl -s 'http://localhost:9090/api/v1/query?query=agrisense%3Asensor_dropout_rate%3A5m' | jq '.data.result'

🪜 STEP 2 — Auto-Provision Grafana Dashboards
(a) Dashboard Provisioner

📄 grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1
providers:
  - name: 'Agrisense Dashboards'
    orgId: 1
    folder: 'Agrisense'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/content
(b) Dashboard JSON
📄 grafana/provisioning/dashboards/content/agrisense-overview.json

{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": 2,
  "links": [],
  "panels": [
    {
      "datasource": {
        "type": "prometheus",
        "uid": "PBFA97CFB590B2093"
      },
      "fieldConfig": {
        "defaults": {
          "mappings": [],
          "noValue": "✅ No active alarms"
        },
        "overrides": []
      },
      "gridPos": { "h": 4, "w": 6, "x": 18, "y": 0 },
      "id": 9,
      "options": {
        "textMode": "name",
        "graphMode": "none",
        "colorMode": "none",
        "justifyMode": "auto",
        "orientation": "vertical",
        "reduceOptions": {
          "fields": "",
          "values": false,
          "calcs": ["lastNotNull"]
        },
        "text": {
          "titleSize": 10,
          "valueSize": 11
        }
      },
      "pluginVersion": "12.2.0",
      "targets": [
        {
          "datasource": { "type": "prometheus", "uid": "PBFA97CFB590B2093" },        
          "expr": "ALERTS{alertstate=\"firing\"}",
          "instant": true,
          "refId": "A",
          "legendFormat": "{{silo_id}}: {{alertname}}"
        }
      ],
      "title": "Active Alarms",
      "transformations": [
        {
          "id": "renameByRegex",
          "options": {
            "regex": "(.*): CriticalBattery",
            "renamePattern": "🔋 $1: Critical Battery"
          }
        },
        {
          "id": "renameByRegex",
          "options": {
            "regex": "(.*): LowSignalStrength",
            "renamePattern": "📶 $1: Low Signal"
          }
        },
        {
          "id": "renameByRegex",
          "options": {
            "regex": "(.*): Watchdog",
            "renamePattern": "⚠️ $1: Watchdog"
          }
        },
        {
          "id": "renameByRegex",
          "options": {
            "regex": "(.*): (LowFeed|CriticalFeed)",
            "renamePattern": "🚨 $1: Low Feed"
          }
        }
      ],
      "type": "stat"
    },
    {
      "fieldConfig": {
        "defaults": {
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 4, "w": 6, "x": 0, "y": 0 },
      "id": 1,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:fleet_battery_min", "refId": "A" } ],        
      "title": "Fleet Min Battery (%)",
      "type": "stat"
    },
    {
      "fieldConfig": {
        "defaults": {
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 4, "w": 6, "x": 6, "y": 0 },
      "id": 2,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:fleet_weight_sum", "refId": "A" } ],
      "title": "Fleet Total Weight (kg)",
      "type": "stat"
    },
    {
      "fieldConfig": {
        "defaults": {
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 4, "w": 6, "x": 12, "y": 0 },
      "id": 3,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:fleet_signal_p95", "refId": "A" } ],
      "title": "Signal p95 (dBm)",
      "type": "stat"
    },
    {
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": { "legend": false, "tooltip": false, "viz": false },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": { "type": "linear" },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": { "group": "A", "mode": "none" },
            "thresholdsStyle": { "mode": "off" }
          },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 4 },
      "id": 4,
      "options": {
        "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
        "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" }
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:battery_percent:by_silo", "refId": "A" } ],  
      "title": "Battery by Silo (%)",
      "type": "timeseries"
    },
    {
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": { "legend": false, "tooltip": false, "viz": false },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": { "type": "linear" },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": { "group": "A", "mode": "none" },
            "thresholdsStyle": { "mode": "off" }
          },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 4 },
      "id": 5,
      "options": {
        "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
        "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" }
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:signal_dbm:by_silo", "refId": "A" } ],       
      "title": "Signal by Silo (dBm)",
      "type": "timeseries"
    },
    {
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": { "legend": false, "tooltip": false, "viz": false },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": { "type": "linear" },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": { "group": "A", "mode": "none" },
            "thresholdsStyle": { "mode": "off" }
          },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 12 },
      "id": 6,
      "options": {
        "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
        "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" }
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:sensor_dropout_rate:5m", "refId": "A" } ],   
      "title": "Sensor Dropout Rate (5m) by Silo",
      "type": "timeseries"
    },
    {
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic" },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": { "legend": false, "tooltip": false, "viz": false },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": { "type": "linear" },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": { "group": "A", "mode": "none" },
            "thresholdsStyle": { "mode": "off" }
          },
          "mappings": [],
          "thresholds": { "mode": "absolute", "steps": [ { "color": "green", "value": 0 }, { "color": "red", "value": 80 } ] }
        },
        "overrides": []
      },
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 12 },
      "id": 7,
      "options": {
        "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
        "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" }
      },
      "pluginVersion": "12.2.0",
      "targets": [ { "expr": "agrisense:weight_kg:by_silo", "refId": "A" } ],        
      "title": "Silo Weight (kg)",
      "type": "timeseries"
    },
    {
      "fieldConfig": { "defaults": {}, "overrides": [] },
      "gridPos": { "h": 8, "w": 24, "x": 0, "y": 20 },
      "id": 8,
      "options": {
        "alertInstanceLabelFilter": "",
        "alertName": "",
        "dashboardAlerts": false,
        "groupBy": [],
        "groupMode": "default",
        "maxItems": 20,
        "showInactiveAlerts": false,
        "sortOrder": 1,
        "stateFilter": { "error": true, "firing": true, "noData": false, "normal": false, "pending": true, "recovering": true },
        "viewMode": "list"
      },
      "pluginVersion": "12.2.0",
      "title": "Active Alerts",
      "type": "alertlist"
    }
  ],
  "preload": false,
  "refresh": "10s",
  "schemaVersion": 42,
  "tags": ["agrisense"],
  "templating": { "list": [] },
  "timepicker": {},
  "timezone": "",
  "title": "Agrisense — Overview",
  "uid": "agri-overview",
  "version": 1
}


(c) Mount in Docker Compose

In docker-compose.yml under grafana service:

    volumes:
      - ./grafana/provisioning:/etc/grafana/provisioning:ro


♻️ Restart Grafana:

docker compose restart grafana
sleep 2
curl -s http://localhost:3000/api/health | jq .

🪜 STEP 3 — API Verification

Set credentials (they’re already in .env — not checked into Git):
📁 Check folder:

curl -s -u $GUSER:$GPASS http://localhost:3000/api/folders | jq -r '.[].title'
# expect: Agrisense


📊 Check dashboard:

curl -s -u $GUSER:$GPASS http://localhost:3000/api/dashboards/uid/agri-overview \
 | jq -r '.dashboard.title'
# expect: Agrisense — Overview


Then open Grafana UI:
➡️ Dashboards → Agrisense → Agrisense — Overview

🪜 STEP 4 — Verifier Script

📄 script/phase_3/verify-phase3.sh

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


chmod +x script/phase_3/verify-phase3.sh
bash script/phase_3/verify-phase3.sh
🪜 STEP 5 — Git Commit & Tag
bash
Copy code
git add prometheus/rules/recording.yml \
        grafana/provisioning/dashboards/dashboards.yml \
        grafana/provisioning/dashboards/content/agrisense-overview.json \
        docker-compose.yml \
        script/phase_3/verify-phase3.sh

git commit -m "feat(phase-3): add Prometheus recording rules and auto-provisioned Grafana overview dashboard + verifier"
git tag -a phase-3 -m "Phase 3 – Dashboards & Recording Rules"
git push origin main --tags
