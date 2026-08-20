#!/bin/bash

source /home/ubuntu/.monitor_env

SERVICE=("health" "report")

declare -A URLS

URLS["health"]="http://localhost:8899/health"
URLS["report"]="http://localhost:8899/report"

CHECK_LIMIT=3
CHECK_SECONDS=10

DNS_THRESHOLD=5.0
CONNECT_THRESHOLD=5.0
STARTTRANSFER_THRESHOLD=5.0
TOTAL_THRESHOLD=5.0

alert_triggered=0

declare -A dns_fail_count
declare -A connect_fail_count
declare -A starttransfer_fail_count
declare -A total_fail_count
declare -A http_fail_count

for service in "${SERVICE[@]}"; do
    dns_fail_count["$service"]=0
    connect_fail_count["$service"]=0
    starttransfer_fail_count["$service"]=0
    total_fail_count["$service"]=0
    http_fail_count["$service"]=0
done

LOG_FILE="/home/ubuntu/log-processing-system/phase7-monitoring-lab/monitor.log"

write_log(){
    local message=$1
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] $message" | tee -a "$LOG_FILE"

}

check_latency(){
    local actual=$1
    local threshold=$2
    local current_fail_count=$3

    if awk "BEGIN { exit !($actual > $threshold) }"; then
        current_fail_count=$((current_fail_count +1))
    else
        current_fail_count=0
    fi

    echo "$current_fail_count"
}

check_http_status(){
    local http_status=$1
    local current_fail_count=$2

    if [ "$http_status" != "200" ]; then
        current_fail_count=$((current_fail_count+1))
    else
        current_fail_count=0
    fi

    echo "$current_fail_count"
}

send_notification(){
    local message=$1
    curl -s -f -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=${message}" > /dev/null
}

monitor_endpoint(){
    local service_name=$1
    local url="${URLS[$service_name]}"
    for ((check_number=1; check_number<=CHECK_LIMIT; check_number++)); do
        curl_output=$(curl -s -o /dev/null -w "%{time_namelookup} %{time_connect} %{time_starttransfer} %{time_total} %{http_code}" "$url")
        read -r dns_time connect_time starttransfer_time total_time  http_status <<< "$curl_output"

        dns_fail_count["$service_name"]=$(
            check_latency \
            "$dns_time" \
            "$DNS_THRESHOLD" \
            "${dns_fail_count["$service_name"]}"
        )

        connect_fail_count["$service_name"]=$(
            check_latency \
            "$connect_time" \
            "$CONNECT_THRESHOLD" \
            "${connect_fail_count["$service_name"]}"
        )

        starttransfer_fail_count["$service_name"]=$(
            check_latency \
            "$starttransfer_time" \
            "$STARTTRANSFER_THRESHOLD" \
            "${starttransfer_fail_count["$service_name"]}"
        )

        total_fail_count["$service_name"]=$(
            check_latency \
            "$total_time" \
            "$TOTAL_THRESHOLD" \
            "${total_fail_count["$service_name"]}"
        )

        http_fail_count["$service_name"]=$(
            check_http_status \
            "$http_status" \
            "${http_fail_count["$service_name"]}"
        )

        if [ "${dns_fail_count["$service_name"]}" -ge "$CHECK_LIMIT" ]; then
            alert_message="ALERT service=$service_name DNS latency failed ${CHECK_LIMIT} times in a row"
            write_log "$alert_message"
            send_notification "$alert_message"
            alert_triggered=1
        fi

        if [ "${connect_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
            alert_message="ALERT service=$service_name connect latency failed ${CHECK_LIMIT} times in a row"
            write_log "$alert_message"
            send_notification "$alert_message"
            alert_triggered=1
        fi

        if [ "${starttransfer_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
            alert_message="ALERT service=$service_name STARTTRANSFER latency failed ${CHECK_LIMIT} times in a row"
            write_log "$alert_message"
            send_notification "$alert_message"
            alert_triggered=1
        fi


        if [ "${total_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
            alert_message="ALERT service=$service_name TOTAL latency failed ${CHECK_LIMIT} times in a row"
            write_log "$alert_message"
            send_notification "$alert_message"
            alert_triggered=1
        fi


        if [ "${http_fail_count[$service_name]}" -ge "$CHECK_LIMIT" ]; then
            alert_message="ALERT service=$service_name HTTP status was not 200 for ${CHECK_LIMIT} times in a row"
            write_log "$alert_message"
            send_notification "$alert_message"
            alert_triggered=1
        fi
        
        if [ "$check_number" -lt "$CHECK_LIMIT" ]; then
            sleep "$CHECK_SECONDS"
        fi
    done        
}

for service in "${SERVICE[@]}"; do
    monitor_endpoint "$service"
done

if [ "$alert_triggered" -eq 1 ]; then
    exit 1
else
    exit 0
fi
