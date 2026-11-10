# 模式 B：SSH 采集 + Actions 代推

适合：摘要在自家机器上（VPS / 家宽 NAS / 面板容器），且该机器访问 PushDeer API 不稳定（海外超时常见）。  
参考：WorkBuddy VPS 运维通知、甲骨文 VPS 状态通知。

## 架构

```text
schedule / 手动
    │
    ▼
GitHub Actions
    ├─ 用 VPS_SSH_KEY 登录 VPS_HOST
    ├─ 远程执行「只采集」脚本，拿到 TITLE + DESP
    └─ 在 Actions 上 curl 推 PushDeer
```

机器侧：**不装 PushDeer cron，不放 pushkey**。

## 最少 Secrets（固定 3 个）

| Name | 填什么 |
|------|--------|
| `PUSHDEER_KEY` | App 内 `PDU…` |
| `VPS_HOST` | `user@x.x.x.x`（x 换你的地址，勿提交仓库） |
| `VPS_SSH_KEY` | SSH 私钥；**推荐 Base64 单行** |

生成 Base64（本机）：

```bash
base64 < ~/.ssh/your.key | pbcopy
```

也支持直接粘贴 PEM / OpenSSH 多行全文；workflow 会兼容三种粘贴方式（见模板注释）。

## 落地步骤

1. 机器上放采集脚本（示例 [`examples/collect_status.sh`](../examples/collect_status.sh)）

   ```bash
   # 目录名自定，但要与 workflow 里 SSH 命令路径一致
   chmod +x ~/your-app/collect_status.sh
   ```

2. 仓库用 [`examples/workflow-ssh-relay.yml`](../examples/workflow-ssh-relay.yml)，改远程脚本路径
3. 配齐 3 个 Secrets → 手动 `Run workflow`
4. 手机收到后，再开 schedule

## 采集脚本约定

远程命令 stdout：

```text
第一行 = 推送标题
其余行 = 推送正文（Markdown 可）
```

Actions 侧：

```bash
TITLE="$(printf '%s\n' "$STATUS" | head -n 1)"
DESP="$(printf '%s\n' "$STATUS" | tail -n +2)"
```

正文过长时截断到约 3500 字符，避免接口拒收。

## 为何不在机器上直推

- 海外出口访问 `api2.pushdeer.com` 易超时
- pushkey 集中在 Actions Secrets，机器被入侵也不直接泄露通知钥
- 与 Mac 是否开机无关

若机器在国内且网络稳定，也可以本机 cron 直推；仍建议复用 [`examples/push.sh`](../examples/push.sh)，密钥放机器本地 env，勿进 git。
