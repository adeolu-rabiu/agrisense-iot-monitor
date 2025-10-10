Runbook — Phase 2: Device Simulator + Alerts (Baby-Steps Edition)

Goal: add a Python simulator that publishes MQTT telemetry and exposes Prometheus metrics, wire Prometheus to scrape it, load alert rules, (optionally) route critical alerts to Slack, and verify end-to-end.

0) Prereqs

Phase-1 stack is up and healthy (prometheus, grafana, alertmanager, mqtt-broker)

Docker + Docker Compose installed

Python is not required on the host (we run in a container)

Your repo layout (minimum):

.
├─ docker-compose.yml
├─ prometheus/
│  ├─ prometheus.yml
│  └─ rules/
│     └─ base.yml
├─ alertmanager/
│  └─ alertmanager.yml
├─ grafana/provisioning/datasources/datasource.yml
├─ mosquitto/mosquitto.conf
└─ device-simulator/               # (we’ll add)

1) Files (these should match what you already have)
1.1 device-simulator/Dockerfile
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY simulator.py .

# Defaults; overridden by docker-compose env
ENV SIMULATOR_SILO_COUNT=5 \
    SIMULATOR_SCRAPE_PORT=8081 \
    SIMULATOR_MQTT_HOST=mqtt-broker \
    SIMULATOR_MQTT_PORT=1883 \
    SIMULATOR_FORCE_LOW_BATTERY=false \
    SIMULATOR_FORCE_LOW_SIGNAL=false \
    SIMULATOR_FORCE_DROPOUT=false

CMD ["python", "simulator.py"]

1.2 device-simulator/simulator.py
import os
import time
import json
import random
import paho.mqtt.client as mqtt
from prometheus_client import start_http_server, Gauge, Counter

# --- Environment ---
SILO_COUNT = int(os.getenv("SIMULATOR_SILO_COUNT", "5"))
MQTT_HOST = os.getenv("SIMULATOR_MQTT_HOST", "mqtt-broker")
MQTT_PORT = int(os.getenv("SIMULATOR_MQTT_PORT", "1883"))
SCRAPE_PORT = int(os.getenv("SIMULATOR_SCRAPE_PORT", "8081"))

FORCE_LOW_BATTERY = os.getenv("SIMULATOR_FORCE_LOW_BATTERY", "false").lower() == "true"
FORCE_LOW_SIGNAL  = os.getenv("SIMULATOR_FORCE_LOW_SIGNAL", "false").lower() == "true"
FORCE_DROPOUT     = os.getenv("SIMULATOR_FORCE_DROPOUT", "false").lower() == "true"

# --- Prometheus metrics (define ONCE) ---
device_weight = Gauge('device_weight_kg', 'Current silo weight in kg', ['silo_id'])
signal_strength = Gauge('signal_strength_dbm', 'Signal strength (dBm)', ['silo_id'])
battery_level = Gauge('battery_level_percent', 'Battery level (%)', ['silo_id'])
sensor_dropout = Counter('sensor_dropout_total', 'Sensor dropouts', ['silo_id'])

class SiloSimulator:
    def __init__(self, silo_idx, mqtt_host=MQTT_HOST, mqtt_port=MQTT_PORT):
        self.silo_id = f"Silo_{silo_idx}"
        self.weight = random.randint(8000, 16000)  # 8–16t
        self.signal = random.randint(-85, -65)     # dBm
        self.battery = random.randint(40, 100)     # %
        self.client = mqtt.Client(client_id=self.silo_id)
        try:
            self.client.connect(mqtt_host, mqtt_port, 60)
            self.client.loop_start()
            print(f"[OK] Connected {self.silo_id} to MQTT {mqtt_host}:{mqtt_port}")
        except Exception as e:
            print(f"[ERR] MQTT connect failed for {self.silo_id}: {e}")

        # Pre-register labels so the series exist immediately
        device_weight.labels(silo_id=self.silo_id).set(self.weight)
        signal_strength.labels(silo_id=self.silo_id).set(self.signal)
        battery_level.labels(silo_id=self.silo_id).set(self.battery)
        sensor_dropout.labels(silo_id=self.silo_id).inc(0)

    def update_metrics(self):
        if FORCE_LOW_BATTERY:
            self.battery = 15
        else:
            if random.random() < 0.05:
                self.battery = max(0, self.battery - 1)

        if FORCE_LOW_SIGNAL:
            self.signal = -95
        else:
            self.signal += random.randint(-5, 5)
            self.signal = max(-100, min(-60, self.signal))

        # Simulated dropout (skips publish, increments counter)
        if FORCE_DROPOUT and random.random() < 0.5:
            sensor_dropout.labels(silo_id=self.silo_id).inc()
            return False
        if not FORCE_DROPOUT and random.random() < 0.05:
            sensor_dropout.labels(silo_id=self.silo_id).inc()
            return False

        self.weight += random.randint(-100, 20)
        self.weight = max(1000, min(18000, self.weight))
        return True

    def publish(self):
        if self.update_metrics():
            device_weight.labels(silo_id=self.silo_id).set(self.weight)
            signal_strength.labels(silo_id=self.silo_id).set(self.signal)
            battery_level.labels(silo_id=self.silo_id).set(self.battery)

            payload = {
                "silo_id": self.silo_id,
                "weight_kg": self.weight,
                "signal_dbm": self.signal,
                "battery_percent": self.battery,
                "timestamp": int(time.time())
            }
            topic = f"agrisense/{self.silo_id}/telemetry"
            self.client.publish(topic, json.dumps(payload))
            print(f"{self.silo_id}: {self.weight}kg | {self.signal}dBm | {self.battery}% -> {topic}")

def main():
    print("Starting AgriSense Device Simulator...")
    start_http_server(SCRAPE_PORT)
    silos = [SiloSimulator(i) for i in range(1, SILO_COUNT + 1)]
    while True:
        for s in silos:
            s.publish()
        time.sleep(15)

if __name__ == "__main__":
    main()

1.3 docker-compose.yml (service block & healthcheck)
  device-simulator:
    build: ./device-simulator
    container_name: device-simulator
    env_file:
      - ./.env
    environment:
      SIMULATOR_SCRAPE_PORT: "${SIMULATOR_SCRAPE_PORT:-8081}"
      SIMULATOR_SILO_COUNT:  "${SIMULATOR_SILO_COUNT:-5}"
      SIMULATOR_MQTT_HOST:   "${SIMULATOR_MQTT_HOST:-mqtt-broker}"
      SIMULATOR_MQTT_PORT:   "${SIMULATOR_MQTT_PORT:-1883}"
      SIMULATOR_FORCE_LOW_BATTERY: "${SIMULATOR_FORCE_LOW_BATTERY:-false}"
      SIMULATOR_FORCE_LOW_SIGNAL:  "${SIMULATOR_FORCE_LOW_SIGNAL:-false}"
      SIMULATOR_FORCE_DROPOUT:     "${SIMULATOR_FORCE_DROPOUT:-false}"
    ports:
      - "${SIMULATOR_SCRAPE_PORT:-8081}:8081"
    depends_on: [mqtt-broker, prometheus]
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8081/metrics').read(); print('ok')\""]
      interval: 20s
      timeout: 5s
      retries: 3
      start_period: 20s
    networks: [agrisense-net]

1.4 Prometheus job and rules

prometheus/prometheus.yml

global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']

  - job_name: 'agrisense-simulator'
    scrape_interval: 10s
    static_configs:
      - targets: ['device-simulator:8081']


prometheus/rules/base.yml

groups:
  - name: sanity
    rules:
      - alert: Watchdog
        expr: vector(1)
        labels: {severity: info}
        annotations:
          summary: "Watchdog"
          description: "Always-firing alert to verify Prometheus → Alertmanager."

  - name: agrisense_device_alerts
    interval: 30s
    rules:
      - alert: LowSignalStrength
        expr: signal_strength_dbm < -90
        for: 5m
        labels: {severity: warning, component: connectivity}
        annotations:
          summary: "Low signal strength detected"
          description: "Device {{ $labels.silo_id }} signal {{ $value }} dBm"

      - alert: CriticalBattery
        expr: battery_level_percent < 20
        for: 10m
        labels: {severity: critical, component: power}
        annotations:
          summary: "Critical battery level"
          description: "Device {{ $labels.silo_id }} battery at {{ $value }}%"

      - alert: SensorDropout
        expr: rate(sensor_dropout_total[5m]) > 0.1
        for: 2m
        labels: {severity: critical, component: sensor}
        annotations:
          summary: "Sensor dropout detected"
          description: "Silo {{ $labels.silo_id }} experiencing sensor failures"

      - alert: HighWeightCapacity
        expr: (device_weight_kg / 18000) > 0.95
        for: 1h
        labels: {severity: warning, component: capacity}
        annotations:
          summary: "Silo nearly full"
          description: "Silo {{ $labels.silo_id }} at {{ $value | humanizePercentage }} capacity"

2) Bring up / restart the stack
# Build simulator image and start it
docker compose up -d --build device-simulator

# Ensure Prometheus picks up the job & rules
docker compose restart prometheus

3) Quick sanity checks (copy/paste)
# Container health (should turn healthy after start_period + checks)
docker inspect --format '{{.State.Health.Status}}' device-simulator
# If "unhealthy", show last five attempts:
docker inspect --format '{{json .State.Health.Log}}' device-simulator | jq '.[-5:]'

# Metrics from host
curl -sf http://localhost:${SIMULATOR_SCRAPE_PORT:-8081}/metrics | head

# Prometheus target should be UP and scraping device-simulator:8081
curl -s http://localhost:9090/api/v1/targets \
 | jq -r '.data.activeTargets[] | select(.labels.job=="agrisense-simulator") | .health,.scrapeUrl'

4) Verify end-to-end with the provided script
sudo apt-get update -y && sudo apt-get install -y curl jq mosquitto-clients
bash script/phase_2/verify-phase2.sh


Expected at the end:

🎯 PHASE 2 VERIFIED


The script confirms:

simulator endpoint serves metrics

Prometheus target agrisense-simulator is up

metrics exist: device_weight_kg, signal_strength_dbm, battery_level_percent, sensor_dropout_total

label silo_id is present

MQTT telemetry is flowing

rule group agrisense_device_alerts is loaded

(optional) test alerts when FORCE flags are enabled

5) Forcing alerts (temporary test mode)

Edit .env at repo root:

SIMULATOR_FORCE_LOW_BATTERY=true
SIMULATOR_FORCE_LOW_SIGNAL=true
SIMULATOR_FORCE_DROPOUT=true


Apply and re-verify:

docker compose restart device-simulator prometheus
sleep 25
bash script/phase_2/verify-phase2.sh


Turn the flags back to false when finished and restart device-simulator.

6) Troubleshooting (specific to your setup)

Simulator shows “unhealthy”
Your healthcheck runs a tiny Python urllib probe inside the container. If it’s unhealthy:

docker inspect --format '{{json .State.Health}}' device-simulator | jq
docker logs device-simulator --tail=200


Make sure :8081/metrics is reachable (you already confirmed with curl and from inside the container).

Prometheus target DOWN
Ensure the job name and target match exactly:

# Should output "up" and the device-simulator URL
curl -s http://localhost:9090/api/v1/targets \
 | jq -r '.data.activeTargets[] | select(.labels.job=="agrisense-simulator") | .health,.scrapeUrl'


If not, fix prometheus/prometheus.yml (block above) and:

docker compose restart prometheus


sensor_dropout_total empty
You pre-register series; counts rise only when dropouts occur. Either wait for natural 5% dropouts or set:

SIMULATOR_FORCE_DROPOUT=true


then restart the simulator and check:

curl -s 'http://localhost:9090/api/v1/query?query=sensor_dropout_total' | jq '.data.result | length'


MQTT telemetry not observed

timeout 10s mosquitto_sub -h localhost -t 'agrisense/+/telemetry' -C 1 -v
docker logs device-simulator --tail=200
docker logs mqtt-broker --tail=200

7) What “done” looks like

device-simulator container running (health: healthy after a few checks)

Prometheus target agrisense-simulator is up

PromQL returns series for:

battery_level_percent, signal_strength_dbm, device_weight_kg, sensor_dropout_total

Alerts visible via API/UI:

always: Watchdog

with force flags enabled long enough for for: durations: CriticalBattery, LowSignalStrength, SensorDropout

script/phase_2/verify-phase2.sh ends with “PHASE 2 VERIFIED”

8) (Optional) Commit & tag (matching Phase-2 content)
git add device-simulator/ prometheus/prometheus.yml prometheus/rules/base.yml docker-compose.yml script/phase_2/verify-phase2.sh
git commit -m "feat(phase-2): device simulator + Prometheus scrape + alert rules; healthcheck via Python urllib; verifier script"
git tag -a phase-2 -m "Phase 2 – Device Simulator & Alerts integrated and verified"
git push origin main --tags
