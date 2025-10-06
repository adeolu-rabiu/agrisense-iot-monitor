AgriSense IoT Monitor — Phase 1 Implementation Runbook

Title: Docker Baseline Setup
Objective: Deploy Prometheus, Grafana, Alertmanager, and Mosquitto MQTT Broker in Docker Compose with auto-provisioned Grafana datasource and test monitoring pipeline.

🧩 1. System Requirements
Component	Minimum	Recommended
OS	Ubuntu 22.04 / 24.04 (x86_64)	Ubuntu 24.04 LTS
RAM	8 GB	16 GB
CPU	2 vCPUs	4 vCPUs
Disk	50 GB	150 GB
Network	Internet Access	Bridged Adapter (LAN access)
⚙️ 2. Prerequisites (from Phase 0)

Docker & Docker Compose installed

Node.js and Python ready

User added to Docker group (sudo usermod -aG docker $USER)

Verified with:

docker --version
docker compose version

🧱 3. Phase 1 Architecture Overview
Service	Port	Purpose
Prometheus	9090	Metrics collection
Grafana	3000	Dashboards
Alertmanager	9093	Alert routing
MQTT Broker (Mosquitto)	1883 / 9001	Device message transport
🧾 4. Directory Structure
agrisense-iot-monitor/
├── docker-compose.yml
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
│       └── base.yml
├── alertmanager/
│   └── alertmanager.yml
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasource.yml
├── mosquitto/
│   └── mosquitto.conf
└── docs/
    └── runbook-phase1.md

🛠️ 5. Implementation Steps
Step 1 – Create .env file
cat > .env.example <<'EOF'
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORDplaceholder1
GF_SERVER_ROOT_URL=http://localhost:3000
COMPOSE_PROJECT_NAME=agrisense
EOF

cp .env.example .env

Step 2 – Create docker-compose.yml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
    ports:
      - "9090:9090"
    networks:
      - agrisense-net

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
      - GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
      - GF_SERVER_ROOT_URL=${GF_SERVER_ROOT_URL}
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - agrisense-net

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    command:
      - --config.file=/etc/alertmanager/alertmanager.yml
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    ports:
      - "9093:9093"
    networks:
      - agrisense-net

  mqtt-broker:
    image: eclipse-mosquitto:2
    container_name: mqtt-broker
    volumes:
      - ./mosquitto/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
    ports:
      - "1883:1883"
      - "9001:9001"
    networks:
      - agrisense-net

networks:
  agrisense-net:
    driver: bridge

volumes:
  grafana-data:

Step 3 – Prometheus Config

prometheus/prometheus.yml

global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - "/etc/prometheus/rules/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['prometheus:9090']


prometheus/rules/base.yml

groups:
  - name: sanity
    rules:
      - alert: Watchdog
        expr: vector(1)
        labels:
          severity: info
        annotations:
          summary: "Watchdog"
          description: "Always-firing alert to verify Prometheus → Alertmanager."

Step 4 – Alertmanager Config

alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m

route:
  receiver: 'null-receiver'
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 3h

receivers:
  - name: 'null-receiver'

Step 5 – Mosquitto Config

mosquitto/mosquitto.conf

listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest stdout

Step 6 – Grafana Auto-Provisioning

grafana/provisioning/datasources/datasource.yml

apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

Step 7 – Launch the stack
docker compose up -d
docker compose ps

🧪 6. Validation Commands
Container Health
docker compose ps

Prometheus Readiness
curl -s http://localhost:9090/-/ready && echo

Grafana Health
curl -s http://localhost:3000/api/health | jq .

Alertmanager Status
curl -s http://localhost:9093/api/v2/status | jq .

Grafana Datasource Check
curl -s -u admin:placeholder1 http://localhost:3000/api/datasources | jq .

Check Alerts
curl -s http://localhost:9090/api/v1/alerts | jq .


⚠️ If you see "alerts": [], the Watchdog may not be loaded yet. Wait 30s or reload Prometheus UI → Alerts tab.

🔧 7. MQTT Broker Test

Install test client:

sudo apt install -y mosquitto-clients


Run subscriber in one terminal:

mosquitto_sub -h localhost -t test/topic -C 1


Then, in a second terminal, publish:

mosquitto_pub -h localhost -t test/topic -m "hello"


✅ If you see hello echoed in the subscriber terminal, the broker works fine.

If you don’t see "hello", check the network binding:

docker logs mqtt-broker | grep "listener"
netstat -tuln | grep 1883


Restart container if needed:

docker compose restart mqtt-broker

🧾 8. Phase 1 Acceptance Criteria
Test	Status
Containers running (docker compose ps)	✅
Prometheus Ready (curl /ready)	✅
Grafana Health	✅
Grafana Datasource provisioned	✅
Alertmanager responding	✅
Watchdog firing	✅ (after ~30s)
MQTT publish/subscribe	✅
�� 9. Troubleshooting
Symptom	Cause	Fix
Watchdog not firing	Rules folder not mounted	Verify docker-compose.yml volume mapping
Invalid username/password for Grafana API	Wrong credentials	Check .env file and restart Grafana
MQTT not echoing	Topic mismatch or broker stopped	Restart broker and use same topic
Prometheus exited	Mounted directory instead of file	Use prometheus/rules/*.yml approach
Grafana shows no datasource	Provisioning folder not mounted	Check volume path in docker-compose
🏁 10. Sign-off Criteria

✅ Containers healthy
✅ Prometheus /alerts shows “Watchdog”
✅ Grafana accessible and connected
✅ MQTT broker verified via CLI
✅ Alertmanager cluster ready

🎯 Phase 1 Summary

The Phase 1 Docker baseline successfully deployed and validated the AgriSense monitoring stack:

Core services operational (Prometheus, Grafana, Alertmanager, MQTT)

Grafana datasource auto-provisioned

Watchdog alert verified

MQTT communication tested
Environment is now ready for Phase 2: Device Simulator + Prometheus Alert Routing.
