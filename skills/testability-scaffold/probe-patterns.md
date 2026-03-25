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

### URL 可访问

```bash
# HTTP 可达
curl -s -o /dev/null -w "%{http_code}" <url>
# 成功标准：200

# 检查是否重定向到登录页
curl -s -o /dev/null -w "%{redirect_url}" <url>
# 如果重定向到 /login → 需要认证
```

### Playwright 可用性

```bash
# Playwright 已安装
npx playwright --version 2>/dev/null

# 浏览器已下载
npx playwright install --dry-run 2>/dev/null
# 或检查浏览器二进制文件是否存在
```

### 本地服务启动检查

```bash
# 如果服务未运行，检查启动命令是否存在
grep -q '"dev"' package.json && echo "有 dev 脚本" || echo "无 dev 脚本"
grep -q '"start"' package.json && echo "有 start 脚本" || echo "无 start 脚本"
```

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
| 浏览器 DevTools (Console/Network) | 运行时调试工具，非外部可探测 | 只要浏览器可达（第 7 节），DevTools 即可用。无需单独探测 |
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
