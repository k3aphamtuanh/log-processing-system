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
## Sample Input

```text
2026-04-30 10:00:00 | IP:192.168.1.10 | STATUS:500 | TIME:2300ms
2026-04-30 10:00:01 | IP:192.168.1.11 | STATUS:200 | TIME:1800ms
2026-04-30 10:00:02 | IP:192.168.1.12 | STATUS:404 | TIME:120ms
invalid log line
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

## Key Concepts Practiced

- reading input from standard input
- parsing and validating log lines
- classifying HTTP status codes and latency levels
- aggregating counts with dictionaries
- sorting results to find top IP addresses
- writing reports to output files

## Current Scope

This project is a command-line log processing tool.

It focuses on:
- parsing server log lines
- detecting HTTP errors and slow requests
- aggregating results by IP
- generating text-based reports

It does not include a web dashboard, database, or alert notification system yet.

## Future Improvements

Planned improvements:
- add alert rules for repeated errors
- add hourly summary reports
- support more log formats
- improve test cases for invalid logs

## What It Detects

- `ERROR:WARNING`: HTTP 4xx client-side errors
- `ERROR:CRITICAL`: HTTP 5xx server-side errors
- `SLOW:ELEVATED`: latency from 500ms to 999ms
- `SLOW:HIGH`: latency from 1000ms to 1999ms
- `SLOW:CRITICAL`: latency from 2000ms or higher

## Requirements

- Python 3.x
- No external libraries required

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
## How to Read the Report

- Lines starting with `ERROR` indicate HTTP error responses.
- Lines starting with `SLOW` indicate high latency requests.
- `Total BOTH` means requests that were both error and slow.
- `Top ERROR IPs` shows IP addresses with the most error responses.
- `Top SLOW IPs` shows IP addresses with the most slow requests.

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
