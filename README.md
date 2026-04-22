# Log Processing System

## Overview
This system processes log data from standard input and analyzes errors and latency levels.

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
