#!/bin/bash

HEALTH_URL="http://localhost:8899/health"
REPORT_URL="http://localhost:8899/report"

health_status=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")
report_status=$(curl -s -o /dev/null -w "%{http_code}" "$REPORT_URL")

if [ "$health_status" = "200" ]; then
  health_up=1
else
  health_up=0
fi

if [ "$report_status" = "200" ]; then
  report_up=1
else
  report_up=0
fi

echo "health_status=$health_status health_up=$health_up"
echo "report_status=$report_status report_up=$report_up"
