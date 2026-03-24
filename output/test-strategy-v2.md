# 测试策略提案：fz — 飞书网盘 CLI 工具

> 生成时间：2026-03-23
> 项目：fz（飞书网盘/Wiki Shell 风格 CLI）
> 阶段：策略对齐（阶段一）

---

## 1. 需求概述

### 我们要测什么

`fz` 是一个基于飞书 Node SDK 的 CLI 工具，将飞书网盘和 Wiki 封装为 Linux shell 风格的文件操作命令。核心价值是让用户用熟悉的 shell 命令操作飞书云端文件。

### 测试范围

基础文件操作命令：
- `fz ls` — 列出文件/文件夹
- `fz mkdir` — 创建文件夹
- `fz cat` — 查看文件内容
- `fz rm` — 删除文件/文件夹
- `fz cp` — 复制文件
- `fz mv` — 移动/重命名文件
- 路径解析 — `/drive/...` 和 `/wiki/...` 的虚拟路径系统

### 不在范围内

- Wiki 空间管理（创建/删除空间）— 超出基础文件操作
- 权限管理和分享功能 — 后续版本
- 文件上传/下载 — 后续版本（涉及本地文件系统交互）

---

## 2. 环境画像

### 维度快照

| 维度 | 值 |
|------|-----|
| 代码仓库 | CLI 工具（Node.js + TypeScript + 飞书 Node SDK） |
| 服务端 | 无独立服务端 — CLI 直接调飞书 API |
| 数据库 | 无本地数据库 — 所有状态在飞书云端 |
| 前端 | 无前端 |
| 验证通道 | 飞书 SDK 直接调 API（独立于 CLI） + stdout 输出比对 |
| 认证 | 应用凭证（tenant_access_token），有专用测试应用 |
| 数据策略 | 通过飞书 API 创建和清理，测试数据用前缀隔离 |

### 基础设施详情

| 组件 | 位置 | 状态 | 访问方式 |
|------|------|------|----------|
| 飞书 API | 远程（飞书开放平台） | 可用 | 飞书 Node SDK |
| 数据存储 | 飞书云端 | 可读写（有测试应用权限） | SDK API 调用 |
| 前端 | 无 | — | — |

### 已有测试基础设施

- **测试框架**：无（新项目，建议 Vitest）
- **已有测试**：无
- **CI/CD**：无

---

## 3. 测试理念

### 整体策略

`fz` 是一个纯粹的 CLI 包装层——它的全部价值在于**正确调用飞书 API 并将结果格式化为 shell 友好的输出**。如果 mock 掉飞书 API，���试就失去了意义——你只是在验证自己写的 mock 是否正确。

因此我们采用**纯集成测试策略**：所有测试直接对真实飞书 API 做端到端调用。每个测试都是"执行 CLI 命令 → 通过飞书 SDK 独立验证结果"的闭环。

这个策略的代价是：测试速度较慢（每次调飞书 API 都有网络开销），且依赖飞书服务可用性。但对于 CLI 工具来说，这是正确的权衡——我们宁可测得慢但测得真。

### 验证通道与组合

| 通道 | 工具 | 角色 |
|------|------|------|
| 飞书 SDK 直接调用 | `@larksuiteoapi/node-sdk` | **独立验证通道** — 绕过 CLI，直接查飞书 API 确认操作结果 |
| stdout 输出 | CLI 进程 stdout 捕获 | **输出格式验证** — 验证 CLI 输出的格式和内容是否正确 |
| CLI 退出码 | process.exitCode | **错误处理验证** — 验证错误场景返回正确退出码 |

**关键原则**：执行用 CLI（被测对象），验证用 SDK（独立通道）。例如，执行 `fz mkdir /drive/test-folder` 后，不用 `fz ls` 验证，而是用飞书 SDK 直接调 API 确认文件夹存在。这避免了"被测模块自证"的问题。

### 集成测试分层

```
第 1 层：认证与连接
  └─ 验证：SDK 能用 tenant_access_token 成功调通飞书 API
  └─ 验证：CLI 能正确读取配置并建立认证

第 2 层：只读操作（ls, cat）
  └─ 依赖：第 1 层通过
  └─ 前置：通过 SDK 预先创建测试文件和文件夹
  └─ 验证：CLI 输出内容与 SDK 查询结果一致

第 3 层：写操作（mkdir, rm, cp, mv）
  └─ 依赖：第 1、2 层通过
  └─ 验证：执行 CLI 写命令后，通过 SDK 独立确认飞书云端状态变化

第 4 层：路径解析与错误处理
  └─ 依赖：第 1、2、3 层通过
  └─ 验证：虚拟路径（/drive/..., /wiki/...）正确映射
  └─ 验证：不存在的路径、权限不足等场景返回正确错误信息和退出码
```

---

## 4. 数据流闭环

### 数据从哪来？

通过飞书 SDK 直接调 API 创建。每次测试运行在飞书网盘中创建一个带时间戳前缀的隔离文件夹（如 `fz-test-20260323-143022/`），所有测试数据在此文件夹内操作。

### 数据怎么送入环境？

飞书 SDK 直接调用创建 API：
- 创建测试文件夹：`drive.createFolder()`
- 创建测试文档：`docx.createDocument()` + 移动到测试文件夹
- Wiki 测试空间中创建节点（如测试应用有 Wiki 权限）

### 怎么验证结果？

**独立通道验证**——CLI 执行操作后，用飞书 SDK 直接查 API 确认：

| CLI 命令 | 验证方式 |
|---------|---------|
| `fz ls /drive/path` | 比对 stdout 输出 vs SDK `drive.listFiles()` 返回 |
| `fz mkdir /drive/new-folder` | SDK `drive.getFileMeta()` 确认文件夹存在 |
| `fz rm /drive/file` | SDK `drive.getFileMeta()` 确认返回 404 |
| `fz cat /wiki/space/doc` | 比对 stdout vs SDK `wiki.getNodeContent()` |
| `fz cp /drive/src /drive/dst` | SDK 确认 dst 存在且内容与 src 一致 |
| `fz mv /drive/src /drive/dst` | SDK 确认 dst 存在 + src 不存在 |

### 怎么清理？

测试完成后（无论成功还是失败），通过 SDK 调用 `drive.deleteFile()` 递归删除整个 `fz-test-*` 文件夹。使用 `afterAll` 钩子确保清理执行。

额外保障：可以加一个定期清理脚本，删除超过 24 小时的 `fz-test-*` 文件夹，防止测试中断导致的残留。

### 示例：`fz mkdir` 完整闭环

```
准备 → SDK 创建隔离根目录 fz-test-20260323-143022/
执行 → 运行 CLI: fz mkdir /drive/fz-test-20260323-143022/new-folder
验证 → SDK 调 drive.listFiles(rootFolder) 确认 new-folder 出现在列表中
     → SDK 调 drive.getFileMeta(newFolderId) 确认类型为 folder
     → 检查 CLI stdout 输出符合预期格式
     → 检查 CLI 退出码为 0
清理 → SDK 递归删除 fz-test-20260323-143022/
```

---

## 5. 认证方案

### 方式

应用凭证（tenant_access_token）— 使用专用测试飞书应用。

### 策略说明

测试专用飞书应用的好处：
- 操作范围隔离，不影响正式业务数据
- 可以自由创建/删除文件，支持完整测试闭环
- App ID 和 App Secret 通过环境变量注入，不入代码库

### 需要用户提供的信息

测试运行前需配置以下环境变量：

```bash
FEISHU_APP_ID=cli_xxxx        # 测试应用的 App ID
FEISHU_APP_SECRET=xxxx         # 测试应用的 App Secret
```

可以用 `.env.test` 文件管理，`.gitignore` 中排除。

---

## 6. 环境前置条件

阶段二（环境探测验证）需要逐一验证的条件：

- [ ] Node.js 已安装：`node --version`（建议 >= 18）
- [ ] 飞书测试应用已创建，App ID / Secret 可用
- [ ] 测试应用已开通「云文档」权限（`drive:drive`）
- [ ] 测试应用已开通「知识库」权限（`wiki:wiki`，如需测试 Wiki 命令）
- [ ] 环境变量已配置：`echo $FEISHU_APP_ID`
- [ ] 飞书 API 可达：`curl -s https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal` 返回非超时
- [ ] SDK 认证成功：编写一个最小脚本调用 `getTenantAccessToken()` 验证凭证有效

---

## 7. 后续阶段展望

### 阶段二：环境探测验证

逐一验证上述前置条件，确保测试环境就绪。包括：
- 验证飞书 SDK 版本和 API 权限
- 确认测试应用能成功创建/删除文件
- 确认 Wiki 空间权限（如适用）

### 阶段三：测试用例生成 + 数据准备

基于本策略生成：
- 每个 CLI 命令的详细测试用例（正常路径 + 异常路径）
- 测试 helper（SDK 封装的 setup/teardown 工具函数）
- 路径解析的边界测试用例
- CI 集成配置（需处理 secret 注入）
