# Echo-TDD 优化设计（第一轮：文档输出优化）

> 生成时间：2026-04-05
> 项目：Echo-TDD
> 需求来源：[docs/prompts/r7.md](../../prompts/r7.md)
> 优化轮次：第一轮（共三轮）

---

## 1. 背景和问题

### 当前问题

基于用户反馈（r7.md），Echo-TDD 存在以下需要优化的问题（共 11 项）。本轮聚焦解决最紧急的问题：

**优先级 P0（本轮解决）**：
1. **文档输出过大导致超时**：plan.md 可能达到 15K tokens，单次输出导致模型输出极慢甚至超时
2. **文档路径结构不统一**：当前使用 `docs/echo-tdd/<topic>/` 嵌套结构，不符合 superpowers 的平铺 + 时间戳规范

**优先级 P1（第二轮解决）**：
3. Phase 4 方案确认交互应使用结构化提问工具（AskUserQuestion）
4. verify 阶段应在开始时一次性收集信息，减少后续沟通

**优先级 P2（第三轮解决）**：
5. plan 阶段应完全禁止环境探测
6. 强调 MacOS APP 应使用 mac-use
7. 明确竭尽全能使用真实环境，Mock 只用于完全不可达的外部依赖
8. 测试规模默认最全面覆盖
9. 记录需求来源
10. 统一 SKILL 引用格式
11. 确保每个用例都标注优先级

### 为什么先解决文档输出问题

1. **影响面最大**：超时问题导致 plan 阶段完全无法使用
2. **收益最高**：解决后立即可用，其他优化可以在可用基础上迭代
3. **风险最低**：纯文件结构改变，不涉及流程逻辑
4. **向后兼容**：新旧路径可以共存，不破坏现有用户

---

## 2. 设计目标

### 目标 1：彻底解决输出超时问题

**策略**：将单个大文档拆分成多个小文档

**量化指标**：
- 主文档 ≤ 4K tokens
- 详情文档 ≤ 6K tokens  
- checklist 文档 ≤ 3K tokens
- 单次生成 < 10 秒（基于 Claude Sonnet 4.5 的 40-50 tokens/s）

### 目标 2：统一文档路径规范

**策略**：采用 superpowers 的平铺 + 时间戳结构

**设计原则**：
- 时间戳格式：`YYYY-MM-DD`（便于按时间排序）
- 分类目录：`plans/`、`verify/`、`generate/`（对应三个阶段）
- 文件命名：`YYYY-MM-DD-<topic>-<type>.md`（包含后缀，更明确）

### 目标 3：保持用户体验

**约束**：
- 主文档仍然是完整的索引，可以快速浏览
- 详情文档通过相对路径链接，点击即达
- 后续阶段（verify/generate）可以按需读取特定文档

---

## 3. 文档结构设计

### 3.1 目录结构

```
docs/echo-tdd/
├── plans/
│   ├── 2026-04-05-<topic>-plan.md           # 主文档（索引 + 摘要）
│   ├── 2026-04-05-<topic>-observability.md  # 可观测性详情
│   └── 2026-04-05-<topic>-checklist.md      # 环境前置条件
├── verify/
│   └── 2026-04-05-<topic>-verify.md         # 验证报告
└── generate/
    └── 2026-04-05-<topic>-generate.md       # 测试用例文档
```

**命名规范**：
- `<topic>`：用户提供的主题，kebab-case 格式（如 `fz-feishu-sync`）
- 时间戳：生成当天的日期，格式 `YYYY-MM-DD`
- 后缀：`-plan` / `-observability` / `-checklist` / `-verify` / `-generate`

**示例**：
```
2026-04-05-fz-feishu-sync-plan.md
2026-04-05-fz-feishu-sync-observability.md
2026-04-05-fz-feishu-sync-checklist.md
```

### 3.2 主文档结构（plan.md）

**目标大小**：3-4K tokens

**章节划分**：

```markdown
# 可观测性方案：[项目名称]

> 元信息区（生成时间、项目、阶段、详情文档链接）

## 1. 需求概述
- 需求来源（新增）
- 我们要验证什么
- 验证范围
- 不在范围内

## 2. 环境画像
- 维度快照（表格）
- 基础设施详情（表格）
- 已有测试基础设施（列表）

## 3. 可观测性方案（摘要）
> 完整详情链接到 observability.md

- 整体策略（2-3 段话）
- 通道角色（列表）
- 关键组合（简化表格，3-5 行）

## 4. 数据流闭环
（保持完整内容）

## 5. 测试分层概要
（保持完整内容）

## 6. 认证方案
（保持完整内容）

## 7. 环境前置条件
> 完整 checklist 链接到 checklist.md

- 关键前置条件概览（3-5 项）

## 8. 后续阶段展望
（保持完整内容）
```

**变更点**：
1. 元信息区增加详情文档链接
2. 第 1 节增加"需求来源"小节
3. 第 3 节改为摘要 + 链接，完整内容移到 observability.md
4. 第 7 节改为概览 + 链接，完整内容移到 checklist.md

### 3.3 可观测性详情文档（observability.md）

**目标大小**：5-6K tokens

**章节划分**：

```markdown
# 可观测性详情：[项目名称]

> 主文档链接
> 生成时间

## 整体可观测性策略
（4-5 段话详细阐述）

## 基础通道
（完整表格，可能 10+ 行）

### 浏览器子通道展开（如适用）
（DOM、Console、Network、Visual、Storage、URL）

## 组合通道（如有）
（完整表格）

## 触发 × 观测 矩阵（完整版）
（完整表格，可能 20+ 行，包含所有功能模块）

## 约束与局限
- 通道约束
- 功能约束
- 降级方案

## 渐进式真实度（如适用）
（完整表格，包含所有渐进层次）
```

**内容来源**：
- 从当前 output-template.md 的第 3 节提取
- 保留所有详细表格和说明
- 不做压缩，保持完整性

### 3.4 环境前置条件文档（checklist.md）

**目标大小**：2-3K tokens

**章节划分**：

```markdown
# 环境前置条件 Checklist：[项目名称]

> 主文档链接
> 生成时间
> 用途说明

## 第 1 层：基础运行环境
- [ ] 语言版本
  - 验证命令：...
  - 期望：...
- [ ] 包管理器
  ...

## 第 2 层：依赖安装
...

## 第 3 层：认证/凭证
...

## 第 4 层：基础通道可达性
...

## 第 5 层：组合通道可用性
...

## 第 6 层：数据操作权限
...

## Checklist 统计
- 总计：XX 项
- 各层分布
```

**内容来源**：
- 从当前 output-template.md 的第 7 节提取
- 按验证依赖顺序分层（已在 verify SKILL.md 定义）
- 每项包含验证命令和期望结果

---

## 4. 生成流程设计

### 4.1 Phase 5 生成策略

**当前流程**（单次生成）：
```
Phase 5: 方案生成
  └─ Write plan.md (15K tokens) → 超时风险
```

**新流程**（三次生成）：
```
Phase 5: 方案生成
  ├─ 生成主文档 (3-4K tokens)
  │   └─ Write plan.md
  │       - 包含所有章节
  │       - 第 3、7 节为摘要 + 链接
  │
  ├─ 生成可观测性详情 (5-6K tokens)
  │   └─ Write observability.md
  │       - 完整的基础通道表
  │       - 完整的组合通道表
  │       - 完整的触发×观测矩阵
  │       - 约束与局限详情
  │
  └─ 生成环境前置条件 (2-3K tokens)
      └─ Write checklist.md
          - 分层的完整 checklist
          - 每项包含验证命令
```

**执行顺序**：
1. 先生成主文档（用户可以快速预览）
2. 再生成 observability.md（需要主文档确定后的内容）
3. 最后生成 checklist.md（独立性最强，可并行）

### 4.2 topic 提取策略

**问题**：如何确定文件名中的 `<topic>`？

**策略**：

1. **Phase 0 输入解析时提取**：
   - 如果用户提供了文档路径（如 `@docs/spec.md`），从路径中提取（`spec`）
   - 如果用户用自然语言描述（如"测试用户注册流程"），提取关键词（`user-registration`）
   - 如果无参数，提示用户输入 topic 或根据代码库推断（如项目名）

2. **topic 规范化**：
   - 转为 kebab-case（`userRegistration` → `user-registration`）
   - 移除特殊字符
   - 限制长度（建议 ≤ 40 字符）

3. **记录到变量**：
   - 在 Phase 0 提取后，存储为 `planTopic` 变量
   - Phase 5 生成时使用此变量构造文件名

### 4.3 链接引用策略

**相对路径引用**：
```markdown
主文档中：
[可观测性详情](./2026-04-05-fz-feishu-sync-observability.md)

verify.md 中引用 plan：
[可观测性方案](../plans/2026-04-05-fz-feishu-sync-plan.md)
```

**好处**：
- 文件移动时不会失效（同目录内）
- 在 GitHub/本地编辑器中都能正确跳转
- 不依赖绝对路径

---

## 5. 模板文件变更

### 5.1 拆分 output-template.md

**当前**：
```
skills/echo-tdd-plan/
└── output-template.md（单文件模板）
```

**新设计**：
```
skills/echo-tdd-plan/
├── output-template-plan.md           # 主文档模板
├── output-template-observability.md  # 可观测性详情模板
└── output-template-checklist.md      # checklist 模板
```

**理由**：
- 每个模板对应一个输出文件
- SKILL.md 中可以分别引用
- 便于维护和扩展

### 5.2 模板内容分配

#### output-template-plan.md

从当前 output-template.md 提取：
- 完整的章节 1、2、4、5、6、8
- 简化的章节 3（摘要 + 链接）
- 简化的章节 7（概览 + 链接）

#### output-template-observability.md

从当前 output-template.md 的第 3 节提取：
- 整体策略（完整版）
- 基础通道（完整表格）
- 组合通道（完整表格）
- 触发×观测矩阵（完整表格）
- 约束与局限（完整说明）
- 渐进式真实度（完整表格）

#### output-template-checklist.md

从当前 output-template.md 的第 7 节提取：
- 分层结构（6 层）
- 每层的 checklist 格式
- 统计汇总格式

---

## 6. SKILL 修改清单

### 6.1 echo-tdd-plan

**修改文件**：
- `skills/echo-tdd-plan/SKILL.md`
- `skills/echo-tdd-plan/output-template.md` → 拆分为 3 个文件
- `skills/echo-tdd-plan/output-template-plan.md`（新增）
- `skills/echo-tdd-plan/output-template-observability.md`（新增）
- `skills/echo-tdd-plan/output-template-checklist.md`（新增）

**SKILL.md 修改点**：

1. **Phase 0 输入解析** - 增加 topic 提取逻辑：
```markdown
## Phase 0: 输入解析

...

### topic 提取

确定文件名中的 `<topic>` 部分：
- 如果用户提供文档路径，从路径提取
- 如果自然语言描述，提取关键词
- 如果无明显 topic，根据代码库推断或提示用户输入

topic 规范化：
- 转为 kebab-case
- 移除特殊字符
- 限制长度 ≤ 40 字符

记录为 `planTopic` 变量，供 Phase 5 使用。
```

2. **Phase 5 方案生成** - 完全重写：
```markdown
## Phase 5: 方案生成

基于完整的六大维度信息和用户确认的可观测性思路，分三次生成文档。

### 目录和命名

- 主文档：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md`
- 可观测性详情：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-observability.md`
- 环境前置条件：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-checklist.md`

其中：
- `YYYY-MM-DD`：生成当天日期
- `<topic>`：Phase 0 提取的 planTopic 变量

### 生成步骤

**步骤 1：生成主文档**

使用 Write 工具创建 `plan.md`，参考 `output-template-plan.md`。

内容要求：
- 第 1 节增加"需求来源"小节
- 第 3 节为摘要版，添加指向 observability.md 的链接
- 第 7 节为概览版，添加指向 checklist.md 的链接
- 其他章节保持完整

目标大小：3-4K tokens

**步骤 2：生成可观测性详情**

使用 Write 工具创建 `observability.md`，参考 `output-template-observability.md`。

内容要求：
- 顶部添加返回主文档的链接
- 包含完整的基础通道表、组合通道表
- 包含完整的触发×观测矩阵（所有功能模块）
- 详细说明约束与局限
- 如适用，包含完整的渐进式真实度表格

目标大小：5-6K tokens

**步骤 3：生成环境前置条件**

使用 Write 工具创建 `checklist.md`，参考 `output-template-checklist.md`。

内容要求：
- 顶部添加返回主文档的链接
- 按 6 层依赖关系组织
- 每项包含验证命令和期望结果
- 底部添加统计汇总

目标大小：2-3K tokens

### 最终确认

生成三个文档后，告知用户：

> 可观测性方案已生成：
> - 主文档：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md`
> - 可观测性详情：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-observability.md`  
> - 环境前置条件：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-checklist.md`
>
> 请审阅主文档，如有需要可查看详情文档。确认无误后我们可以进入下一阶段。

此时方向已在 Phase 4 对齐，这次确认重点是完整性和细节。
```

3. **下一步引导** - 更新路径引用：
```markdown
### 下一步引导

方案审阅通过后，向用户提问下一步方向：

- **环境确认 + 脚手架**（推荐）— 运行 `/echo-tdd:verify @docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md` 进入阶段二
- **先生成测试用例** — 先看到具体的测试用例，之后再验证环境
```

### 6.2 echo-tdd-verify

**修改文件**：
- `skills/echo-tdd-verify/SKILL.md`

**修改点**：

1. **Phase 0 方案解析** - 更新路径引用：
```markdown
## Phase 0: 方案解析

读取用户提供的可观测性方案：

- 主文档：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md`
- Checklist：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-checklist.md`
- 可观测性详情（按需）：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-observability.md`

用户触发时的参数示例：
- `/echo-tdd:verify @docs/echo-tdd/plans/2026-04-05-fz-feishu-sync-plan.md`

从主文档提取：
- 需求来源（新增字段）
- 环境画像
- 可观测性摘要
- 数据流闭环
- 认证方案

从 checklist 文档提取：
- **完整的环境前置条件清单**（这是 Phase 1 探测的依据）

从可观测性详情文档提取（按需）：
- 完整的触发×观测矩阵
- 约束与局限详情
```

2. **Phase 4 完成输出** - 更新路径引用：
```markdown
## Phase 4: Smoke Test

...

### 完成输出

Smoke test 通过后：
1. 告知用户阶段二完成
2. 总结已确认的环境能力和脚手架内容
3. 将验证报告保存到 `docs/echo-tdd/verify/YYYY-MM-DD-<topic>-verify.md`
4. 提示用户可以进入阶段三——运行 `/echo-tdd:generate @docs/echo-tdd/verify/YYYY-MM-DD-<topic>-verify.md` 生成测试用例文档和数据蓝图
```

### 6.3 echo-tdd-generate

**修改文件**：
- `skills/echo-tdd-generate/SKILL.md`

**修改点**：

1. **Phase 0 输入解析** - 更新路径引用：
```markdown
## Phase 0: 输入解析

读取前两阶段的产出：

- 可观测性方案主文档：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md`
- 可观测性详情：`docs/echo-tdd/plans/YYYY-MM-DD-<topic>-observability.md`
- 验证报告：`docs/echo-tdd/verify/YYYY-MM-DD-<topic>-verify.md`

用户触发时的参数示例：
- `/echo-tdd:generate @docs/echo-tdd/verify/2026-04-05-fz-feishu-sync-verify.md`

从可观测性详情文档提取：
- **完整的触发×观测组合矩阵**（决定每个用例的触发和验收方式）
- 约束与局限（决定降级方案）

从验证报告提取：
- 各通道的 PASS/FAIL/WARN（决定实际可用通道）
```

2. **Phase 5 用户审阅** - 更新路径引用：
```markdown
## Phase 5: 用户审阅

...

### 输出

用户确认后，将用例文档保存到 `docs/echo-tdd/generate/YYYY-MM-DD-<topic>-generate.md`。
```

---

## 7. 向后兼容策略

### 问题

现有用户可能已经使用了旧路径结构：
```
docs/echo-tdd/<topic>/
├── plan.md
├── verify.md
└── generate.md
```

### 策略

**选项 A：完全废弃旧路径**
- 新版本只支持新路径
- 更新文档说明变更
- 风险：破坏现有用户的工作流

**选项 B：双路径支持（推荐）**
- verify 和 generate 阶段同时支持新旧路径
- Phase 0 解析时尝试两种路径格式
- 新生成的文档使用新路径
- 风险：增加维护复杂度，但用户体验平滑

**推荐实施**：选项 B，双路径支持

**实现方式**（以 verify 为例）：
```markdown
## Phase 0: 方案解析

尝试读取可观测性方案，支持新旧两种路径格式：

**新格式（优先）**：
- `docs/echo-tdd/plans/YYYY-MM-DD-<topic>-plan.md`
- `docs/echo-tdd/plans/YYYY-MM-DD-<topic>-checklist.md`

**旧格式（兼容）**：
- `docs/echo-tdd/<topic>/plan.md`

读取策略：
1. 如果用户提供了完整路径参数，按参数读取
2. 如果只提供了 topic，先尝试新格式（按日期倒序查找最新）
3. 如果新格式不存在，尝试旧格式
4. 都不存在，提示用户提供正确路径

从旧格式文档提取时：
- 主文档即为完整内容（没有拆分）
- checklist 在主文档的第 7 节
- 可观测性详情在主文档的第 3 节
```

**过渡期**：保持双路径支持 3-6 个月，然后逐步废弃旧格式。

---

## 8. 测试验证计划

### 8.1 单元测试（文档生成）

**测试场景**：
1. 生成三个文档文件都成功创建
2. 文件名格式正确（日期 + topic）
3. 主文档中的链接指向正确
4. 三个文档大小符合预期（≤6K tokens）

**测试方法**：
- 使用实际的 plan 流程，输入一个中等复杂度的项目
- 检查生成的三个文件
- 验证文件大小和链接有效性

### 8.2 集成测试（跨阶段）

**测试场景**：
1. plan → verify：verify 能正确读取拆分后的 plan 文档
2. verify → generate：generate 能正确读取 observability.md
3. 新旧路径混用：verify 读取旧格式 plan，生成新格式 verify

**测试方法**：
- 完整跑一遍 plan → verify → generate 流程
- 使用示例项目（如 fz 飞书同步）
- 验证每个阶段都能正确读取上一阶段的输出

### 8.3 性能测试

**测试场景**：
1. 大型项目（20+ 功能模块）的 plan 生成时间
2. 三次 Write 的总时间 vs 单次 Write 的时间
3. 验证不会超时（每次 Write < 10 秒）

**测试方法**：
- 准备一个大型项目的输入
- 计时每次 Write 操作
- 对比优化前后的总时间

---

## 9. 实施计划

### 9.1 实施步骤

**Step 1：准备模板文件**（预计 30 分钟）
- 拆分 `output-template.md` 为 3 个文件
- 调整内容分配和链接引用
- Git commit："refactor: split output-template into 3 files"

**Step 2：修改 echo-tdd-plan SKILL**（预计 1 小时）
- 更新 SKILL.md 的 Phase 0、Phase 5、下一步引导
- 测试 Phase 5 的三次生成流程
- Git commit："feat(plan): support multi-file output with timestamps"

**Step 3：修改 echo-tdd-verify SKILL**（预计 30 分钟）
- 更新 SKILL.md 的 Phase 0、Phase 4
- 实现双路径支持逻辑
- Git commit："feat(verify): support new plan path format with backward compatibility"

**Step 4：修改 echo-tdd-generate SKILL**（预计 30 分钟）
- 更新 SKILL.md 的 Phase 0、Phase 5
- 实现双路径支持逻辑
- Git commit："feat(generate): support new path format with backward compatibility"

**Step 5：端到端测试**（预计 1 小时）
- 使用实际项目测试完整流程
- 验证文档生成和跨阶段读取
- 修复发现的问题

**Step 6：更新示例和文档**（预计 30 分钟）
- 更新 examples/ 目录中的示例（如果需要）
- 更新 README.md 中的路径引用
- Git commit："docs: update examples and README for new path structure"

**总预计时间**：4 小时

### 9.2 里程碑

**M1：模板拆分完成**
- 3 个模板文件创建完成
- 内容分配正确
- 验证：文件存在且格式正确

**M2：plan SKILL 支持多文件输出**
- Phase 5 能生成 3 个文件
- 文件名格式正确（包含时间戳）
- 链接引用正确
- 验证：运行 plan 流程，检查生成的文件

**M3：verify 和 generate SKILL 适配新路径**
- Phase 0 能读取新格式文档
- 支持旧格式兼容
- 验证：运行完整流程，检查跨阶段读取

**M4：第一轮优化完成**
- 所有测试通过
- 文档和示例更新
- Git tag："v1.1.0-r1-doc-optimization"

---

## 10. 风险和缓解

### 风险 1：拆分后的文档导航体验变差

**表现**：用户需要打开多个文件才能看到完整信息

**缓解**：
- 主文档保留完整的索引和摘要
- 使用相对路径链接，一键跳转
- 在主文档中明确说明哪些内容在详情文档

**验证**：收集用户反馈，必要时调整摘要的详细程度

### 风险 2：topic 提取不准确

**表现**：自动提取的 topic 不符合用户预期，导致文件名混乱

**缓解**：
- Phase 0 提取后展示给用户确认
- 允许用户手动指定 topic
- 提供 topic 规范化的建议

**验证**：测试多种输入场景（文档路径、自然语言、无输入）

### 风险 3：双路径支持增加维护复杂度

**表现**：verify 和generate 的 Phase 0 逻辑复杂，容易出bug

**缓解**：
- 将路径解析逻辑封装为通用函数（在 SKILL.md 中定义清楚）
- 优先新格式，旧格式作为降级
- 明确过渡期，计划废弃旧格式

**验证**：覆盖新旧格式混用的测试场景

### 风险 4：生成时间变长

**表现**：虽然单次不超时，但三次生成的总时间比原来更长

**缓解**：
- 三次 Write 是串行但独立，不涉及额外计算
- 实际总时间 ≈ 原单次时间（因为 token 总量相同）
- 用户感知上更好（有进度反馈）

**验证**：性能测试对比优化前后的总时间

---

## 11. 后续优化预告

本轮优化（第一轮）聚焦文档输出结构，后续两轮将继续优化：

**第二轮：交互优化**（预计 2026-04-12）
- Phase 4 使用 AskUserQuestion 结构化提问
- verify 阶段开始时一次性收集信息
- 减少用户沟通次数，提升自动化程度

**第三轮：流程和内容完善**（预计 2026-04-19）
- 禁止 plan 阶段的环境探测
- 强调 MacOS APP 使用 mac-use
- 明确 Mock 策略（竭尽全能用真实环境）
- 记录需求来源、统一引用、确保优先级标注

每轮优化独立可用，不阻塞用户使用。

---

## 12. 总结

### 本轮成果

1. **解决输出超时问题**：单文件拆分为 3 个小文件，每个 ≤ 6K tokens
2. **统一路径规范**：采用 superpowers 的时间戳 + 分类目录结构
3. **保持向后兼容**：双路径支持，平滑过渡
4. **提升用户体验**：主文档精简，详情按需查看

### 量化指标

- 主文档：≤ 4K tokens（原 15K → 节省 73%）
- 单次生成时间：< 10 秒（原 30-60 秒 → 节省 67-83%）
- 超时风险：基本消除（从"经常超时"到"几乎不超时"）

### 下一步

完成本轮实施后，立即进入第二轮优化（交互优化），预计 2026-04-12 启动。
