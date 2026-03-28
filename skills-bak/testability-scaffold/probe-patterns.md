# 环境探测模式库

按通道类型组织的探测模式。每个模式包含：探测命令、成功标准、常见失败原因、修复建议。

Agent 应根据策略文档中列出的前置条件，从这里选择适用的探测模式执行。

---

## 1. 基础运行环境

### Node.js

```bash
# 版本检查
node --version
# 成功标准：输出版本号且满足策略文档要求的最低版本
# 常见失败：未安装 → 建议用 nvm 安装；版本过低 → nvm install <version>

# 包管理器
npm --version   # 或 yarn --version / pnpm --version
# 跟随项目已有的 lock 文件判断应该用哪个
```

### Python

```bash
python3 --version
pip3 --version
# 检查是否在 venv 中：echo $VIRTUAL_ENV
```

### Go

```bash
go version
# 检查 go.mod 是否存在
```

### 通用：检查项目依赖是否已安装

```bash
# Node.js
ls node_modules/.package-lock.json 2>/dev/null && echo "已安装" || echo "需要 npm install"

# Python
pip3 list --format=columns 2>/dev/null | head -5

# Go
go list -m all 2>/dev/null | head -5
```

---

## 1.5 被测项目自身的可用性

如果被测项目是 CLI 工具或有启动脚本，需要验证它本身可以运行：

```bash
# CLI 工具可执行
<cli_command> --version 2>/dev/null || <cli_command> --help 2>/dev/null

# 服务可启动（快速检查，不需要长期运行）
timeout 10 npm run dev 2>&1 | head -20
# 检查是否在指定端口监听
sleep 3 && nc -z localhost <port> && echo "服务已启动"
```

**注意**：
- 这一步检查的是项目自身的 CLI/服务是否能跑起来，不是运行环境
- 如果项目尚未开发完成（如 fz 项目处于开发初期），这一步可以跳过
- 从策略文档的"代码仓库"维度判断是否需要此检查

---

### 测试框架

```bash
# Vitest
npx vitest --version 2>/dev/null || echo "Vitest 未安装"

# Jest
npx jest --version 2>/dev/null || echo "Jest 未安装"

# Playwright
npx playwright --version 2>/dev/null || echo "Playwright 未安装"

# pytest
python3 -m pytest --version 2>/dev/null || echo "pytest 未安装"
```

如果测试框架未安装，这不是失败——脚手架生成时会安装。只需记录当前状态。

### SDK

```bash
# 通用模式：尝试 import
node -e "require('<sdk-package-name>')" 2>/dev/null && echo "SDK OK" || echo "SDK 未安装"

# Python
python3 -c "import <sdk_module>" 2>/dev/null && echo "SDK OK" || echo "SDK 未安装"
```

---

## 3. 认证/凭证

### 环境变量/配置文件检查

```bash
# 检查 .env 文件是否存在
ls .env .env.local .env.test 2>/dev/null

# 检查关键环境变量是否已设置（不输出值，只检查是否非空）
[ -n "$APP_ID" ] && echo "APP_ID 已设置" || echo "APP_ID 未设置"
[ -n "$APP_SECRET" ] && echo "APP_SECRET 已设置" || echo "APP_SECRET 未设置"
```

### Token 获取验证

这一步需要写一个小脚本来验证凭证是否有效。模式：

```
1. 使用策略文档中描述的认证方式获取 token
2. 用 token 做一个最小的 API 调用
3. 检查返回是否为 200
```

**注意**：不要在输出中打印完整的 token/secret。只打印前 8 位 + `...`。

### 常见认证方式的探测

| 认证方式 | 探测方法 | 成功标准 |
|---------|---------|---------|
| API Key | 用 key 发一个最小 GET 请求 | 200，非 401/403 |
| App ID + Secret → Token | 调 token 接口 | 返回有效 token |
| 用户名密码 | 调 login 接口 | 返回 session/token |
| Cookie/Auth 文件导入 | 检查文件存在性 + 用 cookie 发请求 | 文件存在且请求返回 200 |
| 自注册 | 尝试注册一个测试账号 | 注册成功或返回"已存在" |
| OAuth/SSO | 无法自动探测 | 向用户确认登录态获取方式 |

---

## 4. 数据库连通性

### PostgreSQL

```bash
# 连通性
psql -h <host> -U <user> -d <db> -c '\conninfo' 2>&1

# 成功标准：输出连接信息
# 常见失败：
#   - "could not connect" → 数据库未运行或地址错误
#   - "password authentication failed" → 密码错误
#   - "database does not exist" → 数据库名错误

# 权限检查
psql -h <host> -U <user> -d <db> -c 'SELECT 1' 2>&1  # 读权限
psql -h <host> -U <user> -d <db> -c 'CREATE TABLE _probe_test (id int); DROP TABLE _probe_test;' 2>&1  # 写权限
```

### MySQL

```bash
mysql -h <host> -u <user> -p<password> -e 'SELECT 1' <db> 2>&1

# 权限检查
mysql -h <host> -u <user> -p<password> -e 'CREATE TABLE _probe_test (id INT); DROP TABLE _probe_test;' <db> 2>&1
```

### MongoDB

```bash
mongosh --host <host> --eval 'db.runCommand({ping: 1})' <db> 2>&1

# 权限检查
mongosh --host <host> --eval 'db.createCollection("_probe_test"); db._probe_test.drop()' <db> 2>&1
```

### SQLite

```bash
# 检查数据库文件是否存在且可读
test -r <db_file> && echo "可读" || echo "不可读"
sqlite3 <db_file> 'SELECT 1' 2>&1
```

### Redis

```bash
redis-cli -h <host> -p <port> ping 2>&1
# 成功标准：返回 PONG
```

### 通用注意事项

- 从 `.env` 文件或策略文档中提取连接参数
- **不要硬编码密码**到探测命令中——从环境变量读取
- 探测创建的任何表/集合必须立即删除
- 使用 `_probe_test` 或 `_fz_test_probe` 前缀避免冲突

---

## 5. API 可达性

### HTTP 健康检查

```bash
# 基础可达性
curl -s -o /dev/null -w "%{http_code}" <base_url>/health
# 或
curl -s -o /dev/null -w "%{http_code}" <base_url>/api/health

# 成功标准：200 或 204
# 常见失败：
#   - 000 → 网络不通或服务未启动
#   - 404 → 没有 health 端点，尝试其他已知端点
#   - 401/403 → 需要认证才能访问
```

### 需要认证的 API

```bash
# 用已获取的 token
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer <token>" <base_url>/api/<endpoint>
```

### 端口检查

```bash
# 检查服务是否在监听
lsof -i :<port> 2>/dev/null | grep LISTEN
# 或
nc -z localhost <port> 2>&1 && echo "端口开放" || echo "端口未开放"
```

---

## 6. SDK 功能验证

不只是 import 通过，还要能执行基本操作。

### 通用模式

写一个最小脚本，执行 SDK 的一个只读操作：

```javascript
// Node.js 示例模式
const sdk = require('<sdk-package>');
const client = new sdk.Client({ /* 凭证 */ });

// 执行一个最小的只读 API 调用
const result = await client.<some_read_operation>();
console.log('SDK 功能验证通过:', result.code === 0 ? 'OK' : 'FAIL');
```

### 关键原则

- 用**只读操作**验证，不要创建/修改数据
- 如果 SDK 需要凭证，使用 Phase 1 第 3 层已验证的凭证
- 记录 SDK 版本号和可用的 API 能力

---

## 7. 浏览器可达性

> **重要**：curl 只能验证 URL 网络层可达，不能证明浏览器自动化可用。
> 如果浏览器是观测通道，**必须实际启动浏览器并完成页面导航验证**，仅 curl 检查不算通过。

---

### 第一步：确认使用哪种浏览器自动化工具

浏览器探测前，先检查项目仓库中是否已有自动化方案：

| 情况 | 处理策略 |
|------|---------|
| 仓库已有 Puppeteer / Cypress / Selenium 等 | 优先沿用已有方案，确保探测基于它执行；如无法运行则与用户确认，再考虑切换到 Playwright |
| 仓库已有旧版 Playwright | 沿用现有版本和配置 |
| 用户不清楚或仓库无任何浏览器自动化 | 使用 Playwright |
| 全新项目 | 使用 Playwright |

**原则**：尊重项目现有投入，不随意引入新工具；实在跑不起来才与用户协商切换。

---

### 第二步：URL 网络层可达

用 `curl` 确认目标 URL 是否可访问、是否会重定向到登录页。

- 成功标准：返回非 000 的状态码（000 = 服务未启动或网络不通）
- 若落地 URL 含 `/login`、`/signin` → 标记需要处理登录态，影响后续探测和脚手架认证设计

服务未启动时：检查项目的 `package.json` 是否有 `dev`/`start` 脚本，询问用户是否先启动服务。

---

### 第三步：自动化工具安装与浏览器二进制检查

确认所选工具（Playwright 或项目已有工具）已安装、浏览器二进制已下载。

- Playwright：检查 `npx playwright --version` 和浏览器二进制是否存在（`playwright install --dry-run`）
- 浏览器二进制缺失是阻塞性问题，必须先修复（`npx playwright install chromium`）才能进行下一步
- 工具包未安装但后续需要 → 记录 WARN，在脚手架生成时安装，不阻塞继续探测

---

### 第四步：实际启动浏览器验证 ⚠️ 必须执行

**仅完成前三步不算浏览器通道通过。** 必须实际启动浏览器、导航到目标页面、验证 DOM 可操作。

根据场景选择以下两种验证模式之一（或两种都做）：

#### 模式 A：Playwright 自动化脚本（测试执行模式）

适用场景：验证自动化脚本可以无人值守地运行，是测试用例的执行基础。

验证要点：
- Chromium 能以 headless 模式启动
- 导航到目标 URL，页面加载到 `domcontentloaded`
- 能读取页面 title、URL、body 文本片段（证明 DOM 可操作）
- 登录态处理：若页面需要认证，验证以下方式能正常导入登录态：
  - **storage state 文件（auth.json）**：Playwright 的 `storageState` 机制，可导入 cookies + localStorage，是推荐方式
  - **用户数据目录（--profile）**：复用浏览器已有的 profile，适合本地调试场景
  - 探测时需确认上述至少一种方式可用，并记录选用的方式供脚手架生成参考

成功标准：浏览器启动、页面可导航、DOM 可操作、登录态可导入。

#### 模式 B：playwright-cli 驱动（Agent 自由探索模式）

适用场景：由 Agent 驱动浏览器进行自由浏览和探索，用于理解页面结构、验证交互流程、探测认证状态。

> **重要区分**：这里指的是 `@playwright/cli` 这个**独立包**（`npm install -g @playwright/cli@latest`），不是 `playwright` 包内置的 `playwright open`/`playwright codegen` 命令，也不是 playwright-mcp。两者命令体系完全不同。

`playwright-cli` 专为 coding agent 设计。Agent 通过离散的 CLI 指令操作浏览器：`open` → `snapshot`（获取 element ref）→ `click/fill/press` 等，每步都返回当前页面状态反馈，token 消耗远低于 MCP。

验证要点：
- `playwright-cli --version` 可执行（确认包已全局安装）
- `playwright-cli open <url>` 能启动浏览器并导航
- `playwright-cli snapshot` 能返回页面结构快照和 element ref（证明 Agent 可操作元素）
- 登录态导入：
  - `playwright-cli state-load <auth.json>` 能加载已保存的 storage state
  - 或 `playwright-cli open <url> --persistent` 使用持久化 profile，跨会话保留登录态
  - 可通过 `PLAYWRIGHT_CLI_SESSION=<name>` 环境变量隔离不同项目的 session

可选增强：`playwright-cli install --skills` 安装 SKILLs 文件，让 Agent 获得更丰富的操作指引。

成功标准：`playwright-cli` 可执行，页面可导航，`snapshot` 返回有效内容，登录态可加载。

---

### 登录态持久化策略

如果目标页面需要登录，必须在探测阶段确认登录态的获取和持久化方式，否则后续所有测试都会被登录页面阻断。

| 方式 | 适用工具 | 适用场景 | 探测验证点 |
|------|---------|---------|-----------|
| storage state 文件（auth.json）| 模式 A（Playwright 脚本）| 推荐。自动化测试首选，可在 CI 中使用 | 确认文件存在且能被 `storageState` 加载；验证加载后页面不再跳转登录页 |
| `playwright-cli state-load <file>` | 模式 B（playwright-cli）| Agent 驱动场景，加载已有登录态 | 执行 `state-load` 后 `goto` 页面，验证不再重定向登录页 |
| `--persistent` / `--profile=<path>` | 两种模式均可 | 本地开发调试，复用已登录的浏览器 profile | 确认 profile 目录存在，带此参数启动后页面已登录 |
| 自动登录脚本 | 模式 A | 凭证已知（用户名+密码），可自动填表后导出 state | 验证凭证配置正确，脚本能执行登录流程并导出 auth.json |
| 手动获取 + 导入 | 两种模式均可 | OAuth/SSO 等无法自动化的登录 | 引导用户手动登录后导出 auth.json / state 文件，验证导入后可用 |

**探测结论必须明确说明**：使用哪种登录态方式、用哪个工具加载、文件路径或 profile 目录在哪，供脚手架生成直接使用。

---

### 探测结果判定

| 状态 | 条件 | 后续处理 |
|------|------|---------|
| ✅ PASS | 浏览器启动、页面可导航、DOM 可操作、登录态可导入 | 浏览器通道确认可用，记录工具版本和 auth 方式 |
| ⚠️ WARN | 页面需要登录但 auth 方式未确认 | 先确认登录态方案再继续 |
| ❌ FAIL（可修复）| 浏览器二进制未下载 / 服务未启动 / auth 文件缺失 | 给出具体修复步骤，修复后重跑此步骤 |
| ❌ FAIL（阻塞）| 项目已有自动化工具无法运行 | 与用户确认：修复现有工具，或切换到 Playwright |

---

## 8. 文件系统

```bash
# 检查目录是否可写
test -w <target_dir> && echo "可写" || echo "不可写"

# 创建测试文件并删除
touch <target_dir>/_probe_test && rm <target_dir>/_probe_test && echo "文件操作正常"
```

---

## 9. 消息队列/事件流

### Kafka

```bash
# 连通性
kafka-console-consumer.sh --bootstrap-server <host>:<port> --topic <topic> --max-messages 1 --timeout-ms 5000 2>&1
```

### RabbitMQ

```bash
# 管理 API
curl -s -u <user>:<pass> http://<host>:15672/api/overview | head -1
```

### WebSocket

```bash
# 简单连接测试（需要 wscat）
timeout 5 wscat -c <ws_url> 2>&1 | head -5
```

---

## 10. APP/客户端界面（移动端/桌面端）

### Android (ADB)

```bash
# ADB 可用
adb version 2>/dev/null

# 设备连接
adb devices 2>/dev/null | grep -v "List of devices"
# 成功标准：至少一个设备显示为 "device" 状态
# 常见失败：无设备 → USB 调试未开启；unauthorized → 需要在设备上确认
```

### iOS

```bash
# Xcode 工具链
xcrun simctl list devices 2>/dev/null | head -10
# 成功标准：有可用的模拟器设备
```

### Appium

```bash
appium --version 2>/dev/null
# 或
npx appium --version 2>/dev/null
```

### 桌面自动化 (mac-use / PyAutoGUI)

```bash
# mac-use（macOS）
which mac-use 2>/dev/null || echo "mac-use 未安装"

# PyAutoGUI（Python）
python3 -c "import pyautogui; print('PyAutoGUI OK')" 2>/dev/null

# 辅助功能权限（macOS，桌面自动化的前提）
# 无法通过脚本自动检查，需要向用户确认
```

---

## 11. 无法自动探测的通道

以下通道类型无法或不适合通过自动脚本探测，应向用户确认：

| 通道 | 原因 | 处理方式 |
|------|------|---------|
| 浏览器 DevTools (Console/Network) | 运行时调试工具，非外部可探测 | 第 7 节步骤 3 的 Playwright 实际启动探测通过后，DevTools 即可用。无需单独探测 |
| 进程流式输出 (stdout/stderr) | 依赖服务是否在运行中 | 在服务启动后自动可用。标注为"依赖服务启动" |
| 日志系统 (ELK/CloudWatch) | 远程服务，探测方式各异 | 向用户确认是否有日志系统访问权限和 URL |
| OAuth/SSO 认证 | 需要人工交互 | 引导用户手动获取 cookie/token |

---

## 探测结果记录格式

每项探测完成后，记录为以下结构（供后续 Phase 使用）：

```
探测项: <名称>
状态: PASS / FAIL / WARN
详情: <具体输出>
影响: <如果失败，影响哪些测试场景>
修复建议: <如果失败，怎么修复>
替代方案: <如果无法修复，用什么替代>
```
