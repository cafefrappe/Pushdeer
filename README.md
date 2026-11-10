# PushDeer 搭建备忘（可复用）

以后接 PushDeer 时先看本仓库：怎么拿 Key、怎么推、两种常见架构怎么选。

> **敏感信息**（pushkey、Cookie、SSH 私钥、公网 IP）只放 GitHub Actions Secrets / 本地备忘，**不要提交仓库**。

## 5 分钟上手

1. 手机装 [PushDeer](https://www.pushdeer.com/product.html)，App 里复制 **pushkey**（一般以 `PDU` 开头）
2. 仓库 → **Settings → Secrets and variables → Actions** → 新建 Secret（见下方命名）
3. 按场景抄对应工作流模板，改定时与业务脚本
4. **Actions → Run workflow** 手动试一次，手机应收到推送

推送 API（官方）：

```text
POST https://api2.pushdeer.com/message/push
  pushkey=...
  text=标题
  desp=正文（可选，支持 Markdown）
```

备用域名：`https://api.pushdeer.com/message/push`。海外机器直连常超时，优先让 **GitHub Actions 代推**。

通用 curl 片段见 [`examples/push.sh`](examples/push.sh)。

## Secret 命名约定

| 推荐名 | 含义 | 备注 |
|--------|------|------|
| `PUSHDEER_KEY` | PushDeer pushkey | 本仓库与 VPS 类方案统一用这个 |
| `PUSHDEER_SENDKEY` | 同上 | GLaDOS 仓库沿用此名，语义相同 |

业务 Cookie、SSH 等另起名字，不要和 pushkey 混在一个 Secret 里。

## 两种架构（怎么选）

| 模式 | 适用 | 要不要 VPS | 谁推 PushDeer |
|------|------|------------|---------------|
| **A. 纯 Actions** | 签到、HTTP API、纯云端任务（如 GLaDOS） | **不需要** | Actions 本机直接推 |
| **B. Actions + SSH** | 状态在自家机器上（面板、Docker、本机指标） | 需要一台可达 SSH 的机器 | Actions 代推（机器只负责采集） |

```text
模式 A（GLaDOS 类）
  GitHub Actions ──跑业务──► 同一 job 里 curl/SDK 推 PushDeer
  （无 VPS；Secrets 通常只要 pushkey + 业务凭据）

模式 B（VPS / 面板类）
  GitHub Actions ──SSH──► 机器采集摘要 ──► Actions 再推 PushDeer
  （海外机常连不上 PushDeer API，故不在机器上直推）
```

- 业务能在 `ubuntu-latest` 上跑完 → 选 **A**，更简单。
- 业务必须碰内网 / Docker / 本机状态 → 选 **B**，机器上**不要**放 pushkey。

详细步骤：

- [模式 A：纯 Actions（无 VPS）](docs/pattern-a-actions-only.md)
- [模式 B：SSH 采集 + Actions 代推](docs/pattern-b-ssh-relay.md)

模板文件：

| 文件 | 用途 |
|------|------|
| [`examples/workflow-actions-only.yml`](examples/workflow-actions-only.yml) | 模式 A 骨架 |
| [`examples/workflow-ssh-relay.yml`](examples/workflow-ssh-relay.yml) | 模式 B 骨架 |
| [`examples/push.sh`](examples/push.sh) | 可被任意 shell 引用的推送函数 |
| [`examples/collect_status.sh`](examples/collect_status.sh) | 模式 B：机器侧「只采集」示例 |

## 定时写法

推荐带时区（与 GLaDOS 一致），少算 UTC：

```yaml
on:
  workflow_dispatch:          # 永远保留：方便手动试推
  schedule:
    - cron: "0 9 * * *"
      timezone: "Asia/Shanghai"
```

若 runner / 语法不支持 `timezone`，再改成 UTC（北京时间 −8 小时），例如每天 09:00 → `0 1 * * *`。

## 自检清单

- [ ] Secret 名与 workflow `secrets.XXX` 完全一致
- [ ] 手动 `Run workflow` 成功，手机收到标题
- [ ] 标题 / 正文别太长（正文建议 < 3500 字符）
- [ ] 模式 B：SSH 私钥用 Base64 单行更稳；机器上脚本路径与 workflow 一致
- [ ] 模式 B：机器**只采集**，不存 `PUSHDEER_KEY`

## 参考实现（外部仓库）

| 仓库 | 模式 | 说明 |
|------|------|------|
| GLaDOS 签到仓库 | A | Actions 跑 Python，`pypushdeer` / `PUSHDEER_SENDKEY`，无 VPS |
| [workbuddy-vps-ops](https://github.com/cafefrappe/workbuddy-vps-ops) | B | Actions SSH 进 VPS 取摘要再推 |
