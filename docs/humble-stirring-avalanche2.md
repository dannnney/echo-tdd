# 计划：构建阶段二 SKILL — 环境确认 + 测试脚手架

## Context

阶段一 SKILL（`/testability`）已稳定，产出一份测试策略提案（markdown）。阶段二的任务是：

1. 以阶段一的策略文档为输入
2. 逐项验证环境前置条件和可观测性通道的可用性
3. 基于确认后的环境能力，生成测试脚手架代码
4. 用一个 smoke test 跑通整个链路，证明脚手架可用

同时需要在阶段一 SKILL 的结尾增加一个过渡提问，让用户选择下一步方向（默认：环境确认 + 脚手架）。

---

## 一、阶段一 SKILL 修改（小改动）

### 文件：`skills/testability/SKILL.md`

在 Phase 4"用户审阅"之后，增加一个"下一步引导"段落：

```markdown
### 下一步引导

策略审阅通过后，向用户提问下一步方向：

- **环境确认 + 脚手架**（推荐）— 先验证环境、搭建测试基础设施，再在阶段三生成具体用例
- **先生成测试用例** — 先看到具体的测试用例，之后再验证环境

默认推荐前者。提示用户可以运行 `/testability-scaffold @<策略文档路径>` 进入阶段二。
```

### 文件：`skills/testability/output-template.md`

更新第 7 节"后续阶段展望"，明确说明阶段二的触发方式和预期产出。

---

## 二、阶段二 SKILL 设计

### 文件结构

```
skills/testability-scaffold/
├── SKILL.md                  ← 主 skill prompt
├── probe-patterns.md         ← 各类环境探测的模式库（怎么测 DB、SDK、API 等）
├── scaffold-guide.md         ← 脚手架生成指导原则（不预设语言，跟随项目技术栈）
└── examples/
    └── cli-feishu-scaffold.md    ← fz 项目的脚手架示例
```

### SKILL.md 核心设计

#### 输入
- **必需**：阶段一策略文档路径（如 `@docs/test-strategy.md`）
- **可选**：用户额外的环境说明

#### 核心原则

```
策略驱动，一切探测基于阶段一产出的前置条件 checklist
探测即验证，每次探测都是一个可观测的 pass/fail
失败不阻塞，通道不可用时调整策略而非报错停止
脚手架即代码，产出物是可运行的代码不是文档
smoke test 收尾，一个最小测试跑通证明一切就绪
```

#### 流程

```
Phase 0: 策略解析
    │  ← 读取阶段一策略文档，提取关键信息
    ▼
Phase 1: 环境探测（按依赖顺序）
    │  ← 逐项执行前置条件 checklist
    │  ← 记录每项的 pass/fail + 详情
    ▼
Phase 2: 探测报告 + 策略调整
    │  ← 向用户展示探测结果
    │  ← 如有通道不可用，提出调整建议
    │  ← 用户确认调整方案
    ▼
Phase 3: 脚手架生成
    │  ← 基于确认后的环境能力生成代码
    ▼
Phase 4: Smoke Test
    │  ← 运行最小测试验证脚手架可用
    ▼
输出：探测报告 + 脚手架代码 + 通过的 smoke test
```

#### Phase 0: 策略解析

从策略文档中提取：
1. **环境前置条件 checklist**（第 6 节）→ 探测清单
2. **可观测性方案**（第 3 节）→ 需要验证的通道
3. **认证方案**（第 5 节）→ 认证验证步骤
4. **数据流闭环**（第 4 节）→ 数据准备/清理能力
5. **技术栈信息**（第 2 节）→ 决定脚手架的语言和框架

#### Phase 1: 环境探测

**探测顺序**（按依赖链）：
```
1. 基础运行环境（语言版本、包管理器）
2. 依赖安装（测试框架、SDK 等）
3. 认证/凭证（token 获取、API key 验证）
4. 基础通道可达性（DB 连通、API 可达、浏览器可访问）
5. 组合通道可用性（SDK 功能验证、辅助工具测试）
6. 数据操作权限（能否创建/读取/删除测试数据）
```

**每项探测的输出格式**：
```
[✅ PASS] Node.js 版本: v20.11.0 (需要 ≥18)
[✅ PASS] 飞书 SDK 已安装: @larksuiteoapi/node-sdk@3.4.2
[✅ PASS] 应用凭证有效: tenant_access_token 获取成功
[❌ FAIL] Wiki API 权限: 403 Forbidden — 需要申请 wiki:space:read scope
[⚠️ WARN] 网盘根目录为空: 可以运行但没有现有数据可用于只读测试
```

**失败处理策略**：
- 基础环境失败（语言/包）→ 给出安装命令，等用户修复后重试
- 认证失败 → 引导用户检查凭证，提供排查步骤
- 通道不可用 → 提出替代方案（如 DB CLI 不可用 → 改用 API 验证）
- 权限不足 → 告知用户需要申请什么权限

详细的探测模式参见 `probe-patterns.md`。

#### Phase 2: 探测报告 + 策略调整

展示探测结果总表，如有失败项：
1. 标记哪些测试场景受影响
2. 提出调整建议（替代通道、降级方案）
3. 用户确认后继续

#### Phase 3: 脚手架生成

基于确认后的环境能力，生成以下代码：

**1. 测试 helper（核心）**
```
test/helpers/
├── auth.ts          ← 认证 helper（获取 token/cookie/session）
├── data-factory.ts  ← 数据创建工厂（通过确认可用的通道创建测试数据）
├── data-cleanup.ts  ← 数据清理（通过确认可用的通道清理）
├── assertions.ts    ← 自定义断言（基于可用的观测通道）
└── client.ts        ← 观测通道客户端（SDK client、DB client 等）
```

**2. 测试配置**
```
test/
├── setup.ts         ← 全局 setup/teardown
├── vitest.config.ts ← 或 jest.config.ts / playwright.config.ts
└── .env.test        ← 测试环境变量模板
```

**3. Smoke test**
```
test/smoke.test.ts   ← 最小测试，验证脚手架可用
```

脚手架的生成指导参见 `scaffold-guide.md`。

> **注意**：`scaffold-guide.md` 不预设特定语言/框架的代码模板，而是提供通用的生成原则和结构指导。Agent 应根据项目实际使用的技术栈（从策略文档第 2 节提取）来决定具体的文件名、测试框架、代码风格。

#### Phase 4: Smoke Test

运行 smoke test，验证：
1. 认证能通过
2. 至少一个观测通道可用
3. 数据创建和清理能跑通

如果 smoke test 通过 → 阶段二完成，提示用户可进入阶段三。
如果失败 → 分析原因，引导修复。

---

## 三、`probe-patterns.md` 设计要点

按通道类型组织探测模式：

- **数据库连通性**：各 DB 类型的探测命令（psql、mysql、mongosh）+ 权限检查
- **API 可达性**：HTTP 健康检查、端点存在性验证
- **SDK 可用性**：import 检查 + 最小功能调用
- **浏览器可达性**：curl 检查 URL + Playwright 启动检查
- **认证验证**：各认证方式的验证步骤
- **文件系统**：读写权限检查
- **消息队列/缓存**：连通性检查

每个模式包含：探测命令、成功标准、失败原因分析、修复建议。

---

## 四、`scaffold-guide.md` 设计要点

不预设特定语言/框架的代码模板。提供通用的脚手架生成原则：

**结构原则**：
- 测试 helper 按职责分文件（认证、数据工厂、清理、通道客户端）
- 全局 setup/teardown 集中管理
- 环境变量统一管理（.env.test 模板）

**生成决策**：
- 测试框架选择：跟随项目已有配置，无配置时根据技术栈推荐主流选择
- 文件命名和风格：跟随项目现有代码风格
- 依赖管理：使用项目已有的包管理器

**必须包含的模块**（不论什么技术栈）：
1. 认证 helper — 基于策略文档第 5 节的认证方案
2. 通道客户端 — 封装已确认可用的观测通道
3. 数据工厂 — 基于策略文档第 4 节的数据准备方案
4. 数据清理 — 基于策略文档第 4 节的清理方案
5. Smoke test — 最小可运行测试

---

## 五、示例文件

### `examples/cli-feishu-scaffold.md`
基于 fz 项目的 v3 策略，展示完整的阶段二产出：
- 探测报告（7 项 checklist 的 pass/fail）
- 脚手架代码（飞书 SDK client helper、数据工厂、cleanup）
- Smoke test（创建测试文件夹 → 验证存在 → 清理）

---

## 六、实施顺序

1. 创建 `skills/testability-scaffold/SKILL.md`
2. 创建 `skills/testability-scaffold/probe-patterns.md`
3. 创建 `skills/testability-scaffold/scaffold-guide.md`
4. 创建 `skills/testability-scaffold/examples/cli-feishu-scaffold.md`
5. 修改 `skills/testability/SKILL.md` — 增加"下一步引导"
6. 修改 `skills/testability/output-template.md` — 更新第 7 节

---

## 七、验证方式

1. 用 fz 项目的 test-strategy-v3.md 作为输入，手动走一遍 Phase 0-4 流程
2. 检查探测输出格式是否清晰
3. 检查生成的脚手架代码是否可以直接运行
4. Smoke test 是否真的能 pass
