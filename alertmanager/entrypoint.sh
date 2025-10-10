#!/bin/sh
set -e

# Simple sed-based substitution (works everywhere)
sed "s|\${SLACK_WEBHOOK_URL}|${SLACK_WEBHOOK_URL}|g" \
    /etc/alertmanager/alertmanager.yml.template \
    > /etc/alertmanager/alertmanager.yml

# Start alertmanager
exec /bin/alertmanager "$@"
