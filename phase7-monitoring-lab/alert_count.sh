#!/bin/bash
FAIL_COUNT=0

for ((i=1;i<=3;i++)); do
    HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8899/health)
    REPORT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8899/report)
    if [ "$HEALTH_STATUS" = "200" ] && [ "$REPORT_STATUS" = "200" ]; then
        echo "check=$i result=OK"
        echo "health_status=$HEALTH_STATUS report_status=$REPORT_STATUS"
        FAIL_COUNT=0
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "check=$i result=FAIL fail_count=$FAIL_COUNT"
        echo "health_status=$HEALTH_STATUS report_status=$REPORT_STATUS"
    fi
    if [ "$i" -lt 3 ]; then
        sleep 10
    fi
done
    if [ "$FAIL_COUNT" -ge 3 ]; then
        echo "ALERT: one or more endpoints failed  3 times in a row"
        exit 1
    else
        echo "OK: ALERT threshold was not reached"
        exit 0
    fi
