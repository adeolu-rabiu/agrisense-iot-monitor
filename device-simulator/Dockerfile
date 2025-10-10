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

