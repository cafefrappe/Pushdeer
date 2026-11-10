# 甲骨文 VPS → PushDeer 每日状态通知

对齐 [workbuddy-vps-ops](https://github.com/cafefrappe/workbuddy-vps-ops) 已跑通方案：由 **GitHub Actions SSH 到 VPS 采集状态，再由 Actions 推 PushDeer**（不依赖 Mac 在线）。

```
GitHub Actions ──SSH──► VPS 采集状态 ──► PushDeer
```

海外 VPS 直连 `api2.pushdeer.com` 常会超时，所以由 Actions 代推。

> **敏感信息**（PushDeer Key、SSH 私钥、公网 IP）只放在 GitHub Actions Secrets / 本地备忘录，**不要写入本仓库**。

## 流程说明

1. Actions 用 `VPS_SSH_KEY` 登录 `VPS_HOST`
2. 在 VPS 上执行 `collect_status.sh`，拿到标题 + 正文
3. Actions 用 `PUSHDEER_KEY` 调用 PushDeer API 推送
4. 优先 `api2.pushdeer.com`，失败再试 `api.pushdeer.com`

定时：每天 **09:00 北京时间**（cron `0 1 * * *` UTC）。也可在 Actions 里手动 `Run workflow`。

## 一次性配置：3 个 Secrets

打开：https://github.com/cafefrappe/Pushdeer/settings/secrets/actions  

| Name | 填什么 |
|------|--------|
| `PUSHDEER_KEY` | PushDeer 的 `PDU…` 密钥 |
| `VPS_HOST` | `ubuntu@你的公网IP` |
| `VPS_SSH_KEY` | SSH 私钥 Base64 单行（推荐） |

生成 `VPS_SSH_KEY`（本机执行，把结果贴进 Secret）：

```bash
base64 < ~/.ssh/your.key | pbcopy
```

也支持直接粘贴 PEM / OpenSSH 多行私钥全文。

然后：`Actions` → `PushDeer VPS Status` → `Run workflow` 试一次。

## VPS 上只需采集脚本

```bash
git clone https://github.com/cafefrappe/Pushdeer.git ~/Pushdeer
chmod +x ~/Pushdeer/collect_status.sh
```

不必在 VPS 上装 PushDeer 直推 cron，也不必在 VPS 上放 `PUSHDEER_KEY`。

若采集脚本路径不是 `/home/ubuntu/Pushdeer/collect_status.sh`，请同步改工作流里的 SSH 命令。

## 推送内容

- 主机名、时间、公网 IP
- 运行时长、负载、CPU
- 内存、根分区
- 磁盘 / 负载异常时标题告警

## 文件

| 文件 | 作用 |
|------|------|
| `.github/workflows/pushdeer-notify.yml` | Actions：SSH 采集 + 推送 |
| `collect_status.sh` | VPS：只采集状态 |
| `.env.example` | 本地实验占位（正式用 Secrets） |
