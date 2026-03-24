# 测试策略提案：fz — 飞书网盘/Wiki CLI 工具

> 生成时间：2026-03-25
> 项目：fz CLI
> 阶段：策略对齐（阶段一）

---

## 1. 需求概述

### 我们要测什么

fz 是一个基于飞书 Node SDK 的 CLI 工具，将飞书网盘和 Wiki 封装为 Linux shell 风格的磁盘操作命令。

### 测试范围

- `fz ls` — 列出网盘/Wiki 目录内容
- `fz cat` — 读取文档内容（网盘文件、Wiki 文档）
- `fz mkdir` — 创建文件夹（网盘目录、Wiki 空间/节点）
- **路径解析** — `/drive/...` 和 `/wiki/[wiki-name]/[doc-name]` 两种路径体系的解析和映射

### 不在范围内

- `rm`、`cp`、`mv`、`upload`、`download` 等扩展命令（后续迭代）
- 性能和并发测试
- 多租户/多用户场景

---

## 2. 环境画像

### 维度快照

| 维度 | 值 |
|------|-----|
| 代码仓库 | CLI 工具（Node.js / TypeScript） |
| 服务端 | 无服务端 — 纯 CLI，直接调飞书 API |
| 数据库 | 无本地数据库 — 所有状态在飞书云端 |
| 前端 | 无 |
| 可观测性 | 触发：CLI 命令（stdout）；观测：飞书 SDK 独立调 API 验证 |
| 认证 | 飞书应用凭证（App ID + App Secret），tenant_access_token |
| 数据策略 | 测试专用空间（网盘文件夹 + Wiki 空间），通过 SDK 创建和清理 |

### 基础设施详情

| 组件 | 位置 | 状态 | 访问方式 |
|------|------|------|----------|
| 飞书 API | 远程（open.feishu.cn） | 可用 | 飞书 Node SDK / HTTP API |
| 数据库 | 无 | — | — |
| 前端 | 无 | — | — |

### 已有测试基础设施

- **测试框架**：无（项目尚未开始）
- **已有测试**：无
- **CI/CD**：无

---

## 3. 测试理念

### 整体策略

fz 是一个包装飞书 API 的 CLI 工具，没有本地数据库，所有状态都在飞书云端。我们采用**纯集成测试策略——直接对真实飞书 API 做端到端调用，不做 mock**。

理由：CLI 工具的核心价值就是正确封装 API 调用 + 路径解析 + 结果格式化。如果 mock 掉飞书 API，测试就只剩字符串拼接逻辑，失去了验证"与飞书真实交互是否正确"的意义。飞书 API 没有沙盒环境，但我们可以创建测试专用空间来隔离影响。

关键原则：**用 CLI 触发操作，用飞书 SDK 独立验证结果，不用 fz 自身验证自身。**

### 可观测性方案

本项目的可观测性方案核心在于：**触发走 CLI（被测系统），验证走 SDK（独立通道）**。飞书 Node SDK + 应用凭证构成了一个强大的组合通道，让我们可以绕过 CLI 直接查询飞书云端状态。

#### 基础通道

| 通道 | 工具 | 作为触发 | 作为观测 |
|------|------|---------|---------|
| CLI 命令执行 | fz 命令 | 执行 ls/cat/mkdir 等操作 | 检查 stdout 输出和 exit code |
| 进程流式输出 | stdout/stderr | — | 检查命令输出内容和格式 |

#### 组合通道

| 通道 | 说明 | 在测试中的作用 |
|------|------|--------------|
| **飞书 SDK + 应用凭证** | 封装了飞书 API 的完整访问能力，可直接 CRUD 网盘和 Wiki | 数据准备（创建测试文件/文档）、独立验证（查询云端状态确认 CLI 操作生效）、清理（删除测试数据） |

#### 触发 × 观测 组合

| 测试场景 | 触发通道 | 观测通道 | 说明 |
|---------|---------|---------|------|
| `fz mkdir` 创建文件夹 | CLI 命令 | SDK 调 API 查询文件夹是否存在 | 独立通道验证，不用 `fz ls` 验证 `fz mkdir` |
| `fz ls` 列目录 | CLI 命令（stdout） | SDK 调 API 获取同一目录内容做比对 | CLI 输出 vs SDK 查询结果交叉验证 |
| `fz cat` 读文档 | CLI 命令（stdout） | SDK 调 API 获取文档内容做比对 | CLI 输出 vs SDK 获取的原始内容 |
| 路径解析 `/wiki/xxx` | CLI 命令 | SDK 解析同一路径 | 验证 CLI 的路径映射逻辑是否正确 |

### 集成测试分层

```
第 1 层：认证与连接
  └─ 验证：SDK 能正确获取 tenant_access_token，CLI 初始化不报错
  └─ 意义：后续所有测试的前提

第 2 层：只读操作（ls、cat）
  └─ 依赖：第 1 层通过
  └─ 前置：用 SDK 在测试空间中提前创建已知结构的文件和文档
  └─ 验证：CLI 输出 vs SDK 查询结果一致
  └─ 意义：只读操作不产生副作用，最安全，优先验证

第 3 层：写操作（mkdir）
  └─ 依赖：第 1、2 层通过
  └─ 验证：CLI 执行 mkdir → SDK 查询确认文件夹已创建
  └─ 清理：SDK 调 API 删除测试创建的文件夹

第 4 层：路径系统端到端
  └─ 依赖：第 1、2、3 层通过
  └─ 验证：完整路径解析链路——从 /wiki/space-name/doc-name 到飞书内部 ID 的映射
  └─ 意义：路径系统是 fz 的核心抽象，串联所有命令
```

---

## 4. 数据流闭环

### 数据从哪来？

通过飞书 SDK 直接调 API 创建（确定性最高）。在测试专用空间中创建已知结构的文件夹和文档，作为测试的前置数据。

### 数据怎么送入环境？

SDK 调飞书 API 创建。具体：
- 网盘：SDK 调 `drive.v1.file.createFolder` 创建文件夹、上传测试文件
- Wiki：SDK 调 `wiki.v2.space.create` 创建测试空间、`wiki.v2.spaceNode.create` 创建节点

### 怎么验证结果？

**独立通道验证**：用飞书 SDK 直接调 API 查询，不用 fz 命令验证 fz 命令。

- `fz mkdir /drive/test-folder` 执行后 → SDK 调 `drive.v1.file.listByFolder` 确认文件夹存在
- `fz ls /drive/test-folder` 输出后 → SDK 调同一 API 获取结果，比对内容一致性
- `fz cat /wiki/space/doc` 输出后 → SDK 调 `docx.v1.document.rawContent` 获取内容，比对

### 怎么清理？

SDK 调飞书 API 删除测试数据：
- 网盘：删除测试文件夹（会级联删除子内容）
- Wiki：删除测试空间或测试节点
- 命名隔离：测试资源统一使用 `_fz_test_` 前缀，避免误删真实数据

### 示例：`fz mkdir` 完整闭环

```
准备 → SDK 创建测试专用根文件夹 /_fz_test_root/
     → 确认文件夹存在且为空

执行 → 运行 `fz mkdir /drive/_fz_test_root/new-folder`
     → 检查 exit code = 0，stdout 无报错

验证 → SDK 调飞书 API 列出 /_fz_test_root/ 的子项
     → 确认 new-folder 存在且类型为文件夹

清理 → SDK 调飞书 API 删除 /_fz_test_root/（级联删除）
```

### 示例：`fz ls` 完整闭环

```
准备 → SDK 在 /_fz_test_root/ 下创建 3 个子文件夹 + 2 个文件
     → 记录创建的资源名称和属性

执行 → 运行 `fz ls /drive/_fz_test_root/`
     → 捕获 stdout 输出

验证 → 解析 stdout，提取列出的文件/文件夹名称
     → 与准备阶段创建的资源名称比对，确认完全一致

清理 → SDK 删除 /_fz_test_root/
```

---

## 5. 认证方案

### 方式

飞书应用凭证（App ID + App Secret）→ tenant_access_token

### 策略说明

CLI 工具和测试验证用同一套应用凭证，但走不同的代码路径：
- CLI 内部的认证模块获取 token → 被测代码
- 测试 helper 中独立实例化 SDK Client 获取 token → 验证代码

两者使用同一个飞书应用，但不共享 token 实例，确保验证的独立性。

### 需要用户提供的信息

- 飞书应用的 App ID 和 App Secret（存入 `.env`，不入版本控制）
- 确认应用已开通的 API 权限 scope（网盘读写 + Wiki 读写）

---

## 6. 环境前置条件

阶段二（环境探测验证）需要逐一验证的条件：

- [ ] Node.js 环境可用：`node --version`（≥18）
- [ ] 飞书 SDK 可安装：`npm install @larksuiteoapi/node-sdk`
- [ ] 应用凭证有效：SDK 调 `auth.v3.tenantAccessToken.create` 返回有效 token
- [ ] 网盘 API 权限可用：SDK 调 `drive.v1.file.listByFolder` 不报权限错误
- [ ] Wiki API 权限可用：SDK 调 `wiki.v2.space.list` 不报权限错误
- [ ] 可创建测试文件夹：SDK 调 `drive.v1.file.createFolder` 创建 `_fz_test_probe/` 后删除
- [ ] 可创建 Wiki 测试空间：SDK 创建测试空间后删除

---

## 7. 后续阶段展望

### 阶段二：环境探测验证

运行上述前置条件 checklist 中的探测脚本，确认飞书 API 连通性和权限。特别关注：
- token 获取是否正常
- 各 API scope 是否已审批通过
- 网盘根目录和 Wiki 空间列表是否可访问

### 阶段三：测试用例生成 + 数据准备

基于本策略生成具体的测试用例，包括：
- 每个命令的正常路径和异常路径用例
- 测试 helper 代码（SDK 封装：创建/查询/清理测试数据）
- 路径解析的边界用例（中文名称、特殊字符、深层嵌套）
- 错误处理用例（无权限、资源不存在、网络超时）
