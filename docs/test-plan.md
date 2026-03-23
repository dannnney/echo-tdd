# 测试方案：fz — 飞书网盘 & Wiki CLI 工具

> 生成时间：2026-03-22
> 项目：fz CLI
> 阶段：方案设计（阶段一）

---

## 1. 需求概述

### 测试目标

验证 `fz` CLI 工具能正确封装飞书网盘和 Wiki API，提供 Linux shell 风格的文件操作体验。

### 测试范围

**浏览类操作：**
- `fz ls [path]` — 列出网盘/Wiki 目录内容
- `fz tree [path]` — 树形展示目录结构
- `fz find [pattern]` — 搜索文件/文档

**读取类操作：**
- `fz cat [path]` — 输出文档内容（支持行号显示 `-n`）
- `fz head [path]` — 输出文档开头部分

**写入类操作：**
- `fz mkdir [path]` — 创建文件夹
- `fz cp [src] [dst]` — 复制文件/文档
- `fz mv [src] [dst]` — 移动/重命名文件/文档
- `fz rm [path]` — 删除文件/文档

**传输类操作：**
- `fz upload [local-path] [remote-path]` — 上传文件到飞书网盘
- `fz download [remote-path] [local-path]` — 下载文件到本地

**编辑类操作：**
- `fz sed [expression] [path]` — 搜索/更新/追加文档内容

**虚拟路径体系：**
- `/drive/...` — 飞书网盘路径
- `/wiki/[space-name]/[doc-name]` — Wiki 知识库路径

### 不在范围内

- 飞书消息、日历、审批等非文档功能
- 用户 OAuth 授权流程（第一版只用应用凭证）
- 多租户/多应用切换

---

## 2. 环境画像

### 2.1 代码仓库

- **类型**：CLI 工具
- **技术栈**：Node.js + TypeScript + `@larksuiteoapi/node-sdk`
- **关联 repo**：无
- **代码权限**：完全读写（本地开发）

### 2.2 基础设施

| 组件 | 位置 | 状态 | 访问方式 |
|------|------|------|----------|
| 服务端 | 飞书云端 API | 始终可用 | `https://open.feishu.cn/open-apis/` |
| 数据库 | 无（飞书云端存储） | N/A | 通过飞书 API 访问 |
| 前端 | 无 | N/A | CLI 终端交互 |

### 2.3 已有测试基础设施

- **测试框架**：无（需搭建）
- **已有测试**：无
- **CI/CD**：无

### 2.4 推荐测试工具栈

| 工具 | 用途 | 安装命令 |
|------|------|----------|
| Vitest | 测试框架 + 运行器 | `npm install -D vitest` |
| `@larksuiteoapi/node-sdk` | 飞书 SDK | `npm install @larksuiteoapi/node-sdk` |
| Commander.js / yargs | CLI 参数解析 | `npm install commander` |

---

## 3. 验证通道

| 通道 | 工具 | 连接方式 | 用途 |
|------|------|----------|------|
| CLI 输出 | 直接执行 `fz` 命令 | `node ./bin/fz.js <command>` 或 `npx fz <command>` | 验证命令输出格式、退出码 |
| 飞书 API | `@larksuiteoapi/node-sdk` | `https://open.feishu.cn/open-apis/` + tenant_access_token | 验证 API 调用正确性 |
| 飞书管理后台 | 浏览器 | `https://feishu.cn` 登录查看网盘/Wiki | 人工交叉验证文件操作结果 |
| 文件系统 | Node.js `fs` | 本地文件路径 | 验证 upload/download 功能 |

---

## 4. 认证方案

### 方式

应用凭证（app_id + app_secret）→ tenant_access_token

### 具体步骤

1. 用户在飞书开放平台创建自建应用，获取 `app_id` 和 `app_secret`
2. 应用需开通以下权限：
   - `drive:drive` — 云文档/网盘完整权限
   - `wiki:wiki` — Wiki 知识库读写权限
   - `drive:drive:readonly`（至少）— 如果只需只读
3. 配置方式（`fz` 读取凭证的优先级）：
   ```bash
   # 方式 1：环境变量
   export FEISHU_APP_ID=cli_xxx
   export FEISHU_APP_SECRET=xxx

   # 方式 2：配置文件 ~/.fzrc 或 ~/.config/fz/config.json
   {
     "app_id": "cli_xxx",
     "app_secret": "xxx"
   }

   # 方式 3：命令行参数（不推荐，会留在 shell history 中）
   fz --app-id cli_xxx --app-secret xxx ls /drive
   ```
4. `fz` 内部使用 SDK 自动管理 token 刷新：
   ```typescript
   const client = new lark.Client({
     appId: process.env.FEISHU_APP_ID,
     appSecret: process.env.FEISHU_APP_SECRET,
     appType: lark.AppType.SelfBuild,
     domain: lark.Domain.Feishu,
   });
   ```

### 测试用认证凭据

测试时需要设置环境变量 `FEISHU_APP_ID` 和 `FEISHU_APP_SECRET`，指向测试用的飞书应用。

---

## 5. 测试边界

### 需要验证的层

| 层 | 验证方式 | 说明 |
|----|----------|------|
| CLI 参数解析 | 执行命令检查输出 | 路径解析、参数校验、help 输出 |
| 虚拟路径映射 | 执行命令检查 API 调用 | `/drive/xxx` → Drive API, `/wiki/xxx` → Wiki API |
| API 调用层 | 真实飞书 API 调用 | 验证 SDK 调用参数和响应处理 |
| 输出格式化 | 检查 stdout 内容 | ls 表格、cat 内容、错误信息格式 |
| 错误处理 | 故意触发错误场景 | 无权限、路径不存在、网络超时 |

### 不需要验证的层

| 层 | 原因 |
|----|------|
| 飞书 API 服务本身 | 飞书平台保证，不在我们控制范围 |
| 网络连通性 | 基础设施层面，非 CLI 工具职责 |
| SDK 内部实现 | `@larksuiteoapi/node-sdk` 由飞书团队维护 |

### 外部依赖处理

| 依赖 | 处理方式 |
|------|----------|
| 飞书 Open API | 真实调用（纯集成测试策略） |
| 网络 | 测试环境需保证网络可用 |

---

## 6. 数据策略

### 数据存储

飞书云端（非本地数据库），通过 API 进行增删改查。

### 测试数据准备

由于采用纯集成测试，测试数据直接在飞书云端创建和清理：

1. **测试前（setup）**：通过飞书 API 创建测试用的文件夹和文档
   ```bash
   # 在测试应用的网盘根目录创建测试文件夹
   # （通过 fz 自身或直接调用 SDK）
   fz mkdir /drive/fz-test-workspace
   ```

2. **测试后（teardown）**：删除测试创建的所有资源
   ```bash
   fz rm -r /drive/fz-test-workspace
   ```

3. **Wiki 测试数据**：需要预先在测试应用中创建一个测试用的 Wiki 知识空间

### 数据清理策略

- 每次测试运行前，先清理上次残留的测试数据（幂等 setup）
- 测试用文件夹统一使用 `fz-test-` 前缀，便于识别和清理
- 测试失败时 teardown 仍需执行（使用 `afterAll` / `afterEach`）

---

## 7. 测试目标清单

### 7.1 认证与初始化

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 1 | 凭证配置读取 | CLI 输出 | 正确读取环境变量中的 app_id/app_secret | `FEISHU_APP_ID=xxx FEISHU_APP_SECRET=yyy fz ls /drive` → 不报认证错误 |
| 2 | 无凭证时提示 | CLI 输出 | 友好的错误提示，引导用户配置 | `unset FEISHU_APP_ID && fz ls /drive` → 输出配置引导信息，退出码非 0 |
| 3 | 错误凭证处理 | CLI 输出 | 明确的认证失败提示 | `FEISHU_APP_ID=invalid fz ls /drive` → 输出认证失败信息 |

### 7.2 浏览类操作

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 4 | ls 网盘根目录 | CLI + 飞书 API | 列出网盘根目录内容 | `fz ls /drive` → 输出文件/文件夹列表 |
| 5 | ls 网盘子目录 | CLI + 飞书 API | 列出指定目录内容 | `fz ls /drive/fz-test-workspace` → 输出子目录内容 |
| 6 | ls Wiki 空间列表 | CLI + 飞书 API | 列出所有 Wiki 知识空间 | `fz ls /wiki` → 输出知识空间列表 |
| 7 | ls Wiki 空间内容 | CLI + 飞书 API | 列出指定 Wiki 空间中的文档 | `fz ls /wiki/[space-name]` → 输出文档列表 |
| 8 | ls 不存在的路径 | CLI 输出 | 友好的错误提示 | `fz ls /drive/nonexistent` → "No such file or directory" |
| 9 | tree 展示 | CLI 输出 | 树形结构输出 | `fz tree /drive/fz-test-workspace` → 树形目录结构 |
| 10 | find 搜索 | CLI + 飞书 API | 返回匹配的文件列表 | `fz find /drive -name "*.docx"` → 匹配文件列表 |

### 7.3 读取类操作

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 11 | cat 网盘文档 | CLI + 飞书 API | 输出文档纯文本内容 | `fz cat /drive/fz-test-workspace/test-doc` → 文档内容 |
| 12 | cat Wiki 文档 | CLI + 飞书 API | 输出 Wiki 文档内容 | `fz cat /wiki/[space]/[doc]` → Wiki 文档内容 |
| 13 | cat -n 行号显示 | CLI 输出 | 每行带行号输出 | `fz cat -n /drive/test-doc` → `1: xxx\n2: yyy` |
| 14 | head 输出 | CLI 输出 | 只输出前 N 行 | `fz head -20 /drive/test-doc` → 前 20 行 |
| 15 | cat 不存在的文件 | CLI 输出 | 错误提示 | `fz cat /drive/nonexistent` → "No such file" |

### 7.4 写入类操作

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 16 | mkdir 创建文件夹 | CLI + 飞书 API 验证 | 文件夹创建成功 | `fz mkdir /drive/fz-test-workspace/new-folder` → 成功，`fz ls` 可见 |
| 17 | cp 复制文件 | CLI + 飞书 API 验证 | 文件复制到目标路径 | `fz cp /drive/src-file /drive/dst-file` → 目标路径可见 |
| 18 | mv 移动文件 | CLI + 飞书 API 验证 | 文件移动，原位置消失 | `fz mv /drive/old-path /drive/new-path` → 原路径 404，新路径可见 |
| 19 | rm 删除文件 | CLI + 飞书 API 验证 | 文件删除成功 | `fz rm /drive/to-delete` → 成功，`fz ls` 不可见 |
| 20 | rm 删除文件夹 | CLI 输出 | 需要 -r 参数 | `fz rm /drive/folder` → 提示需要 `-r`，`fz rm -r /drive/folder` → 成功 |

### 7.5 传输类操作

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 21 | upload 上传文件 | CLI + 飞书 API + 本地文件系统 | 本地文件上传到飞书网盘 | `fz upload ./test-file.txt /drive/fz-test-workspace/` → 上传成功，`fz ls` 可见 |
| 22 | download 下载文件 | CLI + 本地文件系统 | 飞书文件下载到本地 | `fz download /drive/fz-test-workspace/test-file.txt ./downloaded.txt` → 本地文件内容一致 |
| 23 | upload 大文件 | CLI 输出 | 进度显示，上传成功 | `fz upload ./large-file.zip /drive/` → 显示进度，成功 |

### 7.6 编辑类操作

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 24 | sed 搜索内容 | CLI 输出 | 输出匹配的行 | `fz sed -n '/pattern/p' /drive/test-doc` → 匹配行 |
| 25 | sed 替换内容 | CLI + 飞书 API 验证 | 文档内容被更新 | `fz sed 's/old/new/g' /drive/test-doc` → `fz cat` 验证内容已变更 |
| 26 | sed 追加内容 | CLI + 飞书 API 验证 | 内容追加到文档末尾 | `fz sed '$a\new line' /drive/test-doc` → `fz cat` 验证末尾新增 |

### 7.7 虚拟路径体系

| # | 测试目标 | 验证通道 | 预期结果 | 具体命令/操作 |
|---|----------|----------|----------|---------------|
| 27 | /drive 路径解析 | CLI 输出 | 正确路由到 Drive API | `fz ls /drive` → 网盘内容 |
| 28 | /wiki 路径解析 | CLI 输出 | 正确路由到 Wiki API | `fz ls /wiki` → Wiki 空间列表 |
| 29 | 无效路径 | CLI 输出 | 友好错误 | `fz ls /invalid` → "Unknown path prefix" |
| 30 | 跨域操作 | CLI 输出 | 合理处理 | `fz cp /drive/file /wiki/space/` → 根据实现决定是否支持 |

---

## 8. 环境前置条件

以下是阶段二（环境探测验证）需要逐一验证的条件：

- [ ] Node.js 运行环境可用：`node --version`（需要 >= 18）
- [ ] npm/pnpm 可用：`npm --version`
- [ ] 飞书应用凭证已配置：`echo $FEISHU_APP_ID`（非空）
- [ ] 飞书 API 可达：`curl -s -o /dev/null -w "%{http_code}" https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal`（返回 200）
- [ ] tenant_access_token 可获取：
  ```bash
  curl -s -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
    -H "Content-Type: application/json" \
    -d '{"app_id":"'$FEISHU_APP_ID'","app_secret":"'$FEISHU_APP_SECRET'"}' \
    | grep -o '"tenant_access_token":"[^"]*"'
  ```
- [ ] 飞书应用已开通云文档权限：用获取到的 token 调用 `GET /open-apis/drive/v1/files`（返回 code=0）
- [ ] 飞书应用已开通 Wiki 权限：用获取到的 token 调用 `GET /open-apis/wiki/v2/spaces`（返回 code=0）
- [ ] 测试用 Wiki 知识空间存在且应用有权限访问
- [ ] 本地文件系统可读写（upload/download 测试需要）：`touch /tmp/fz-test && rm /tmp/fz-test`

---

## 附录

### 关键依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `@larksuiteoapi/node-sdk` | latest | 飞书 API SDK |
| `commander` 或 `yargs` | latest | CLI 参数解析 |
| `vitest` | latest | 测试框架 |
| `chalk` 或 `picocolors` | latest | 终端彩色输出 |

### 飞书 API 关键端点

| API | 用途 | 文档 |
|-----|------|------|
| `POST /auth/v3/tenant_access_token/internal` | 获取 token | 认证 |
| `GET /drive/v1/files` | 列出文件 | ls |
| `POST /drive/v1/files/create_folder` | 创建文件夹 | mkdir |
| `POST /drive/v1/files/copy` | 复制文件 | cp |
| `POST /drive/v1/files/move` | 移动文件 | mv |
| `DELETE /drive/v1/files/:fileToken` | 删除文件 | rm |
| `GET /drive/v1/files/:fileToken/download` | 下载文件 | download |
| `POST /drive/v1/medias/upload_all` | 上传文件 | upload |
| `GET /wiki/v2/spaces` | 列出知识空间 | ls /wiki |
| `GET /wiki/v2/spaces/:space_id/nodes` | 列出空间节点 | ls /wiki/xxx |
| `GET /docx/v1/documents/:document_id/raw_content` | 获取文档内容 | cat |

### 虚拟路径映射规则

```
/drive                    → Drive API: 根目录（root folder）
/drive/folder1/file1      → Drive API: 逐级解析 folder token → file token
/wiki                     → Wiki API: 列出所有知识空间
/wiki/[space-name]        → Wiki API: 按名称查找空间 → 列出节点
/wiki/[space-name]/[doc]  → Wiki API: 按名称查找节点 → 获取内容
```
