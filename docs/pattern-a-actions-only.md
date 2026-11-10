# 模式 A：纯 Actions（无 VPS）

适合：签到、打卡、调公开 HTTP API、整段逻辑都能在 GitHub Runner 上跑完。  
参考：GLaDOS 签到（Actions 装依赖 → 跑脚本 → 脚本内推 PushDeer）。

## 架构

```text
schedule / 手动
    │
    ▼
GitHub Actions (ubuntu-latest)
    ├─ checkout + 安装依赖（可选）
    ├─ 跑业务脚本（Cookie / Token 来自 Secrets）
    └─ 同一 job 推 PushDeer（curl 或 SDK）
```

不需要 SSH，不需要公网 IP，不需要常开电脑。

## 最少 Secrets

| Name | 必填 | 说明 |
|------|------|------|
| `PUSHDEER_KEY` 或 `PUSHDEER_SENDKEY` | 要推送才填 | App 内 pushkey |
| 业务凭据（如 Cookie） | 视脚本 | 与 pushkey 分开存 |

都不配 pushkey 时：业务可继续跑，只是跳过通知（GLaDOS 即如此）。

## 落地步骤

1. 仓库加 workflow（抄 [`examples/workflow-actions-only.yml`](../examples/workflow-actions-only.yml)）
2. Secrets 里放 pushkey + 业务凭据
3. 业务脚本结束时调用推送：
   - Shell：`source examples/push.sh && pushdeer_send "标题" "正文"`
   - Python：`pypushdeer`（`PushDeer(pushkey=...).send_text(title, desp=...)`）
4. 手动跑一次确认手机收到

## 推送放哪

两种都可以：

| 方式 | 优点 |
|------|------|
| **脚本内推**（GLaDOS） | 标题/正文跟业务结果强绑定；失败细节好拼 |
| **workflow 里 curl** | 业务脚本保持无推送依赖；失败也能用 `if: always()` 告警 |

推荐默认：**脚本内推**（和 GLaDOS 一致）；只有「多语言 / 只想统一出口」时再提到 workflow。

## 注意

- `concurrency`：定时与手动重叠时避免重复推送（可参考 GLaDOS）
- 推送失败尽量别拖垮主流程（记录日志即可），除非你就是靠推送报警
- Server酱等可并存；PushDeer 与其它通道互不影响
