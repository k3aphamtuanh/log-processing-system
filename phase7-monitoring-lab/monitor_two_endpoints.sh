#!/bin/bash

SERVICES=("health" "report")

declare -A URLS
URLS["health"]="http://localhost:8899/health"
URLS["report"]="http://localhost:8899/report"


CHECK_LIMIT=3
SLEEP_SECONDS=10

DNS_THRESHOLD=5.0
CONNECT_THRESHOLD=5.0
STARTTRANSFER_THRESHOLD=5.0
TOTAL_THRESHOLD=5.0


declare -A dns_fail_count
declare -A connect_fail_count
declare -A starttransfer_fail_count
declare -A total_fail_count


# Counter của health
dns_fail_count["health"]=0
connect_fail_count["health"]=0
starttransfer_fail_count["health"]=0
total_fail_count["health"]=0


# Counter của report
dns_fail_count["report"]=0
connect_fail_count["report"]=0
starttransfer_fail_count["report"]=0
total_fail_count["report"]=0


# Ban đầu chưa có alert
alert_triggered=0


check_latency() {

    local actual=$1
    local threshold=$2
    local current_fail_count=$3

    if awk -v actual="$actual" -v limit="$threshold" '
        BEGIN {
            if (actual > limit) exit 0
            exit 1
        }
    '
    then
        current_fail_count=$((current_fail_count + 1))
    else
        current_fail_count=0
    fi

    echo "$current_fail_count"
}


monitor_endpoint() {

    local service_name=$1
    local url=$2
    local check_number=$3

    local curl_output
    local dns_time
    local connect_time
    local starttransfer_time
    local total_time
    local http_status


    curl_output=$(curl -s -o /dev/null \
        -w "%{time_namelookup} %{time_connect} %{time_starttransfer} %{time_total} %{http_code}" \
        "$url")


    read -r \
        dns_time \
        connect_time \
        starttransfer_time \
        total_time \
        http_status <<< "$curl_output"


    dns_fail_count["$service_name"]=$(check_latency \
        "$dns_time" \
        "$DNS_THRESHOLD" \
        "${dns_fail_count[$service_name]}")


    connect_fail_count["$service_name"]=$(check_latency \
        "$connect_time" \
        "$CONNECT_THRESHOLD" \
        "${connect_fail_count[$service_name]}")


    starttransfer_fail_count["$service_name"]=$(check_latency \
        "$starttransfer_time" \
        "$STARTTRANSFER_THRESHOLD" \
        "${starttransfer_fail_count[$service_name]}")


    total_fail_count["$service_name"]=$(check_latency \
        "$total_time" \
        "$TOTAL_THRESHOLD" \
        "${total_fail_count[$service_name]}")


    echo "check=$check_number service=$service_name http_status=$http_status"

    echo "dns_time=$dns_time dns_fail_count=${dns_fail_count[$service_name]}"

    echo "connect_time=$connect_time connect_fail_count=${connect_fail_count[$service_name]}"

    echo "starttransfer_time=$starttransfer_time starttransfer_fail_count=${starttransfer_fail_count[$service_name]}"

    echo "total_time=$total_time total_fail_count=${total_fail_count[$service_name]}"


    if [ "${dns_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
        echo "ALERT: service=$service_name DNS latency exceeded threshold"
        alert_triggered=1
    fi


    if [ "${connect_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
        echo "ALERT: service=$service_name CONNECT latency exceeded threshold"
        alert_triggered=1
    fi


    if [ "${starttransfer_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
        echo "ALERT: service=$service_name STARTTRANSFER latency exceeded threshold"
        alert_triggered=1
    fi


    if [ "${total_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
        echo "ALERT: service=$service_name TOTAL latency exceeded threshold"
        alert_triggered=1
    fi


    echo "----------------------------------------"
}


for ((check_number=1; check_number<=CHECK_LIMIT; check_number++)); do

    for service_name in "${SERVICES[@]}"; do

        monitor_endpoint \
            "$service_name" \
            "${URLS[$service_name]}" \
            "$check_number"

    done


    if [ "$check_number" -lt "$CHECK_LIMIT" ]; then
        sleep "$SLEEP_SECONDS"
    fi

done


if [ "$alert_triggered" -eq 1 ]; then
    echo "ERROR: one or more latency alert thresholds were reached"
    exit 1
else
    echo "OK: no latency alert threshold was reached"
    exit 0
fi
