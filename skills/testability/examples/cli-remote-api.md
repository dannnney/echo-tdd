# 示例策略提案：CLI 工具包装远程 API

## 维度快照

| 维度 | 值 |
|------|-----|
| 代码仓库 | CLI 工具（Node.js + TypeScript），包装飞书 API |
| 服务端 | 远程（飞书云端 API，始终可用） |
| 数据库 | 无本地 DB（数据全在飞书云端） |
| 前端 | 无（CLI 终端交互） |
| 验证通道 | CLI stdout + 飞书 SDK 直接查询 + 文件系统 |
| 认证 | 应用凭证（app_id + app_secret → tenant_access_token） |
| 数据策略 | 通过 SDK/API 创建和清理（隔离命名空间） |

## 测试理念

### 整体策略

fz 是一个包装飞书 API 的 CLI 工具，没有本地数据库，所有状态都在飞书云端。我们采用**纯集成测试策略**——直接对真实飞书 API 做端到端调用，不做 mock。因为 CLI 工具的价值就在于正确封装 API，mock 掉 API 就失去了测试意义。

关键决策：验证时不能只用 fz 自身来检查结果（循环依赖），需要通过飞书 SDK 独立查询 API 状态做交叉验证。

### 验证通道与组合

| 通道 | 工具 | 角色 |
|------|------|------|
| CLI stdout | 直接执行 fz 命令 | 主驱动——验证输出格式和退出码 |
| 飞书 SDK | @larksuiteoapi/node-sdk | 独立验证——绕过 fz 直接查 API 状态 |
| 文件系统 | Node.js fs | 辅助验证——upload/download 的本地文件 |

### 集成测试分层

```
第 1 层：认证链路
  └─ 凭证配置 → token 获取 → 权限确认
  └─ 验证：fz 命令不报认证错误 + SDK 确认 token 有效

第 2 层：只读操作（ls/cat/find）
  └─ 不改变状态，安全，可以反复跑
  └─ 验证：CLI 输出 + SDK 独立查询同一路径对比

第 3 层：写操作（mkdir/cp/mv/rm/upload/download）
  └─ 改变状态，需要数据准备和清理
  └─ 验证：执行 fz 写操作 → SDK 查 API 确认变更生效
```

## 数据流闭环

| 问题 | 方案 |
|------|------|
| 数据从哪来？ | 通过飞书 SDK 在云端创建（不走 fz，避免循环依赖） |
| 数据怎么送入？ | SDK 调飞书 API 创建隔离的测试目录 `fz-test-{timestamp}/` |
| 怎么验证？ | CLI stdout 检查 + SDK 独立查飞书 API 交叉验证 |
| 怎么清理？ | SDK 调 API 删除 `fz-test-*` 前缀的资源 |

### 示例：验证 fz mkdir

```
准备 → SDK 创建 /drive/fz-test-1711234567/ 隔离目录
执行 → fz mkdir /drive/fz-test-1711234567/new-folder
验证 → SDK 查询该目录下的文件列表，确认 new-folder 存在
     → fz ls 也检查一下输出格式（但不作为唯一验证）
清理 → SDK 删除 /drive/fz-test-1711234567/ 整个目录
```
