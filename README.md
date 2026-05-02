# Log Processing System

## Overview

This system processes log data from standard input and analyzes errors and latency levels.

## Why This Project

This project simulates a basic log monitoring workflow.

It reads raw server logs, detects HTTP errors and slow requests, handles invalid log lines, and generates a summary report for troubleshooting.

## Input Format

Each log line should follow this format:

```text
TIME | IP:<ip_address> | STATUS:<http_status> | TIME:<latency>ms
```

Example:

```text
2026-04-30 10:00:00 | IP:192.168.1.10 | STATUS:500 | TIME:2300ms
```

## Flow

1. Read log data from standard input
2. Parse each line into IP, status, and latency
3. Classify:
   - Error (4xx, 5xx)
   - Latency levels (ELEVATED, HIGH, CRITICAL)
4. Generate report and summary


## Features
- Error classification (HTTP status)
- Latency classification
- Aggregation by IP
- Top error/slow IP detection
- Invalid log handling

## Usage

```bash
cat server_log.txt | python3 main.py
```

## Real-time Usage

```bash
tail -f server_log.txt | python3 main.py
```
## Output Files

- `report.txt`: contains detected error/slow requests and summary statistics
- `invalid_log.txt`: contains invalid log lines that could not be parsed
## Example Output

```text
[ERROR:CRITICAL & SLOW:CRITICAL] Line 5 | IP:192.168.1.10 | Status:500 | Time:2300ms

===== SUMMARY =====
Total lines: 10
Valid lines: 8
Invalid lines: 2
Total ERROR: 3
Total SLOW: 4
Total BOTH: 2

Top ERROR IPs:
1. 192.168.1.10 (2 times)

Top SLOW IPs:
1. 192.168.1.10 (3 times)
```

## Debug Cases

### Case 1: Server Error + High Latency
Status: 500, Time: >2000ms  
→ Server error with high latency before failure  

---

### Case 2: Slow but No Error
Status: 200, Time: >1500ms  
→ No error but potential performance bottleneck  

---

### Case 3: Client Error but Slow
Status: 404, Time: high  
→ Client error but unusually slow response  
