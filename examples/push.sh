#!/usr/bin/env bash
# 通用 PushDeer 推送函数：任意 shell / Actions step 可 source 后调用。
# 依赖环境变量 PUSHDEER_KEY（或兼容 PUSHDEER_SENDKEY）。
#
# 用法：
#   source examples/push.sh
#   pushdeer_send "标题" "正文（可选）"
# 也可直接执行： PUSHDEER_KEY=... ./examples/push.sh "标题" "正文"

pushdeer_send() {
  local title="${1:-}"
  local desp="${2:-}"
  local key="${PUSHDEER_KEY:-${PUSHDEER_SENDKEY:-}}"

  if [ -z "$key" ]; then
    echo "pushdeer_send: 未设置 PUSHDEER_KEY / PUSHDEER_SENDKEY，跳过" >&2
    return 1
  fi
  if [ -z "$title" ]; then
    echo "pushdeer_send: 标题不能为空" >&2
    return 1
  fi

  if [ "${#desp}" -gt 3500 ]; then
    desp="$(printf '%s' "$desp" | head -c 3500)
…(已截断)"
  fi

  local ok=0 base
  for base in \
    "https://api2.pushdeer.com/message/push" \
    "https://api.pushdeer.com/message/push"
  do
    if curl -fsS --connect-timeout 15 --max-time 40 -X POST "$base" \
      --data-urlencode "pushkey=${key}" \
      --data-urlencode "text=${title}" \
      --data-urlencode "desp=${desp}"; then
      echo
      echo "pushed via $base"
      ok=1
      break
    fi
    echo "failed: $base" >&2
  done
  [ "$ok" = 1 ]
}

# 直接执行本文件时：./push.sh "标题" "正文"
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  pushdeer_send "${1:-}" "${2:-}"
fi
