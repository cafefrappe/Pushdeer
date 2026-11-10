#!/usr/bin/env bash
# 模式 B 示例：仅采集本机状态，stdout 第一行=标题，其余=正文（供 Actions 代推）
# 复制到目标机器后改 NOTIFY_TITLE / 采集项即可。
set -euo pipefail

NOTIFY_TITLE="${NOTIFY_TITLE:-主机状态}"

hostname_val="$(hostname 2>/dev/null || echo unknown)"
now_local="$(date '+%Y-%m-%d %H:%M:%S %Z')"
uptime_pretty="$(uptime -p 2>/dev/null || uptime | sed 's/^ //')"
load_avg="$(awk '{print $1", "$2", "$3}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')"

mem_line="N/A"
if command -v free >/dev/null 2>&1; then
  mem_line="$(free -h | awk '/^Mem:/{printf "已用 %s / 总计 %s（可用 %s）", $3, $2, $7}')"
fi

disk_line="N/A"
if command -v df >/dev/null 2>&1; then
  disk_line="$(df -h / | awk 'NR==2{printf "已用 %s / 总计 %s（%s）", $3, $2, $5}')"
fi

cpu_cores="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "?")"

public_ip="获取失败"
if command -v curl >/dev/null 2>&1; then
  public_ip="$(curl -fsS --max-time 8 https://ifconfig.me/ip 2>/dev/null \
    || curl -fsS --max-time 8 https://api.ipify.org 2>/dev/null \
    || echo "获取失败")"
fi

status_emoji="✅"
status_text="正常"
root_pct="$(df -P / 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')"
load1="$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo 0)"
if [[ -n "${root_pct}" ]] && (( root_pct >= 90 )); then
  status_emoji="⚠️"
  status_text="磁盘紧张"
fi
if [[ "${cpu_cores}" =~ ^[0-9]+$ ]]; then
  if awk -v l="${load1}" -v c="${cpu_cores}" 'BEGIN{exit !(l > c*2)}'; then
    status_emoji="⚠️"
    status_text="负载偏高"
  fi
fi

title="${NOTIFY_TITLE} ${status_emoji} ${status_text}"
desp=$(cat <<EOF
**主机**: ${hostname_val}
**时间**: ${now_local}
**公网 IP**: ${public_ip}
**运行时长**: ${uptime_pretty}
**负载 (1/5/15)**: ${load_avg}
**CPU 核心**: ${cpu_cores}
**内存**: ${mem_line}
**根分区**: ${disk_line}
EOF
)

printf '%s\n' "${title}"
printf '%s\n' "${desp}"
