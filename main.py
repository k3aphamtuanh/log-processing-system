import sys

def parse_line(line):
    line = line.strip()

    if not line:
        return None

    parts = line.split("|")
    if len(parts) < 4:
        return None

    try:
        ip = parts[1].split(":")[1].strip()
        status_text = parts[2].split(":")[1].strip()
        status = int(status_ms)
        time_ms = parts[3].split(":")[1].replace("ms", "").strip()
        latency = int(time_ms)
    except (IndexError, ValueError):
        return None

    return ip, status, latency


def is_error(status):
    if 500 <= status < 600:
        return "CRITICAL"
    elif 400 <= status < 500:
        return "WARNING"
    return "OK"


def is_slow(latency):
    if latency >= 2000:
        return "CRITICAL"
    elif 1000 <= latency < 2000:
        return "HIGH"
    elif 500 <= latency < 1000:
        return "ELEVATED"
    return "NORMAL"

def build_labels(status, latency):
    labels = []
    error_level = is_error(status)
    slow_level = is_slow(latency)
    if error_level != "OK":
        labels.append(f"ERROR:{error_level}")
    if slow_level != "NORMAL":
        labels.append(f"SLOW:{slow_level}")
    return labels, error_level, slow_level


stats = {
    "total": 0,
    "invalid": 0,
    "valid": 0,
    "error": 0,
    "slow": 0,
    "both": 0,
}

error_log = {}
slow_log = {}

with (
    open("invalid_log.txt", "w") as f_invalid,
    open("report.txt", "w") as f_report,
):
    for line in sys.stdin:
        stats["total"] += 1
        result = parse_line(line)

        if result is None:
            stats["invalid"] += 1
            f_invalid.write(f"Line {stats['total']}: {line.strip()}\n")
            f_invalid.flush()
            continue

        stats["valid"] += 1
        ip, status, latency = result
        labels, error_level, slow_level = build_labels(status,latency)
    

        if error_level != "OK":
            stats["error"] += 1
            error_log[ip] = error_log.get(ip, 0) + 1

        if slow_level != "NORMAL":
            stats["slow"] += 1
            slow_log[ip] = slow_log.get(ip, 0) + 1

        if error_level != "OK" and slow_level != "NORMAL":
            stats["both"] += 1

        if labels:
            label = " & ".join(labels)
            f_report.write(
                f"[{label}] Line {stats['total']} | IP:{ip} | Status:{status} | Time:{latency}ms\n"
            )
            f_report.flush()

    f_report.write("\n===== SUMMARY =====\n")
    f_report.write(f"Total lines: {stats['total']}\n")
    f_report.write(f"Valid lines: {stats['valid']}\n")
    f_report.write(f"Invalid lines: {stats['invalid']}\n")
    f_report.write(f"Total ERROR: {stats['error']}\n")
    f_report.write(f"Total SLOW: {stats['slow']}\n")
    f_report.write(f"Total BOTH: {stats['both']}\n")

    if error_log:
        top_error_ip = max(error_log, key=error_log.get)
        f_report.write(
            f"Top ERROR IP: {top_error_ip} ({error_log[top_error_ip]} times)\n"
        )

    if slow_log:
        top_slow_ip = max(slow_log, key=slow_log.get)
        f_report.write(
            f"Top SLOW IP: {top_slow_ip} ({slow_log[top_slow_ip]} times)\n"
        )

print("Done. Check invalid_log.txt and report.txt")
