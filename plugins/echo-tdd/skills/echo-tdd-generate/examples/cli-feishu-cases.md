# 示例：fz CLI 项目的阶段三产出

基于 fz 项目的 test-strategy-v3.md（阶段一）+ 环境探测报告（阶段二）。

---

## Phase 0: 输入解析摘要

| 来源 | 提取内容 |
|------|---------|
| 测试范围 | ls、cat、mkdir 命令 + 路径解析（/drive/ 和 /wiki/） |
| 测试分层 | 4 层：认证→只读→写操作→路径端到端 |
| 触发通道 | CLI 命令（stdout/stderr/exitCode） |
| 观测通道 | 飞书 SDK 独立查询（✅ 探测通过） |
| 数据创建 | 通过飞书 SDK 创建（✅ 探测通过） |
| 数据清理 | 网盘→SDK 直删；Wiki→SDK 移入 Trash |
| 数据隔离 | `_fz_test_` 前缀 |

---

## Phase 1: 环境采样摘要

通过飞书 SDK 对真实网盘和 Wiki 空间进行只读采样。

### 采样结果

```
采样通道：飞书 SDK（@larksuiteoapi/node-sdk）

网盘：
  - 根目录子项数：23 个
  - 最大嵌套深度：4 层
  - 单文件夹最多子项：87 个
  - 文件类型分布：folder(45%), docx(32%), file(15%), sheet(5%), bitable(3%)
  - 最长文件名：41 字符（"2024年Q3产品需求评审会议记录"）
  - 含中文文件名：是（占比 62%）
  - 含特殊字符：是（空格 8 个、括号 3 个）

Wiki（龙虾测试环境）：
  - 空间数：5 个
  - 最大节点深度：3 层
  - 节点类型分布：docx(78%), sheet(15%), mindnote(4%), bitable(3%)
  - 最长节点标题：28 字符
  - 含中文标题：是（占比 85%）
```

### 对用例设计的影响

- 嵌套深度测试用 4 层作为现实参考（而非通用的 3 层假设）
- sheet/bitable/mindnote 类型虽然占比低，但需要专门用例（P1 级别）
- 分页阈值：飞书 API 默认 page_size=50，单文件夹最多 87 项 → 测试 50+1 和 87 左右
- 中文文件名占比 62%，中文路径测试标 P0（非 P1）
- 空格和括号实际存在于文件名中 → 特殊字符测试标 P1

---

## 用例清单

### 用例编号规则

`L{层}.{命令}.{序号}` — 如 L2.LS.01 表示第 2 层 ls 命令第 1 个用例

### 通用约定

- **触发通道**：fz CLI 命令（捕获 stdout / stderr / exitCode）
- **观测通道**：飞书 SDK 独立查询（不用 fz 验证 fz）
- **数据隔离**：所有测试资源使用 `_fz_test_` 前缀
- **清理策略**：网盘 → SDK 直删；Wiki → SDK 移入 Trash 节点

---

### 第 1 层：认证与连接

> 前提：无
> 数据策略：无需预置数据

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L1.AUTH.01 | 正常凭证下 CLI 可执行 | .env 中有合法 APP_ID + APP_SECRET | `fz --help` | exitCode=0，输出帮助信息 | stdout | P0 |
| L1.AUTH.02 | 缺少 APP_ID 时报错 | APP_ID 为空 | `fz ls /drive/` | exitCode≠0，stderr 包含凭证提示 | stderr | P0 |
| L1.AUTH.03 | 缺少 APP_SECRET 时报错 | APP_SECRET 为空 | `fz ls /drive/` | exitCode≠0，stderr 包含凭证提示 | stderr | P0 |
| L1.AUTH.04 | 无效凭证时报错 | APP_ID/SECRET 格式正确但无效 | `fz ls /drive/` | exitCode≠0，stderr 包含认证失败提示 | stderr | P0 |
| L1.AUTH.05 | 凭证格式异常 | APP_ID 包含特殊字符 | `fz ls /drive/` | exitCode≠0，合理报错 | stderr | P1 |
| L1.AUTH.06 | SDK 能获取有效 token | .env 配置正确 | SDK verifyAuth() | 返回 true | SDK 直接验证 | P0 |

---

### 第 2 层：只读操作

> 前提：第 1 层通过
> 数据策略：**共享 fixture**——beforeAll 创建，所有只读用例复用

#### fz ls 属性模型

```
path 属性：
  - 路径域: /drive/ | /wiki/
  - 路径深度: 0(根) | 1(一层) | 2+(深层嵌套)
  - 路径字符集: ASCII | 中文 | 特殊字符(空格/括号) | 混合
  - 路径存在性: 存在 | 不存在
  - 末尾斜杠: 有 | 无

目标目录属性：
  - 内容数量: 0(空) | 少量(1-5) | 临界(50) | 超分页(51+) | 大量(87+)
  - 内容类型: 纯文件夹 | 纯文档 | 混合(文件夹+docx+file)
  - 文档子类型: docx | sheet | bitable | mindnote
```

#### fz ls — 网盘

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L2.LS.01 | 列出网盘根目录 | 根目录有文件 | `fz ls /drive/` | exitCode=0，列出根目录内容 | stdout vs SDK listFolder('') 比对 | P0 |
| L2.LS.02 | 列出子文件夹内容 | fixture: 3 个子文件夹 | `fz ls /drive/_fz_test_root/` | 输出包含 alpha, beta, gamma | stdout vs SDK 比对 | P0 |
| L2.LS.03 | 空文件夹返回空 | fixture: 空文件夹 | `fz ls /drive/_fz_test_empty/` | exitCode=0，空输出或提示 | stdout | P0 |
| L2.LS.04 | 不存在的路径报错 | 无 | `fz ls /drive/nonexistent_xyz/` | exitCode≠0 | stderr | P0 |
| L2.LS.05 | 混合类型文件夹 | fixture: folder+docx+file | `fz ls /drive/_fz_test_mixed/` | 所有类型都列出，类型可区分 | stdout vs SDK 比对 | P0 |
| L2.LS.06 | 中文名称文件夹 | fixture: "测试文件夹" | `fz ls /drive/_fz_test_root/` | 中文名正确显示 | stdout | P0 |
| L2.LS.07 | 含空格文件名 | fixture: "my folder" | `fz ls /drive/_fz_test_root/` | 空格正确显示 | stdout | P1 |
| L2.LS.08 | 含括号文件名 | fixture: "报告(修订版)" | `fz ls /drive/_fz_test_root/` | 括号正确显示 | stdout | P1 |
| L2.LS.09 | 分页场景（51 项） | fixture: 51 个子文件夹 | `fz ls /drive/_fz_test_many/` | 所有 51 项都列出 | stdout 行数 vs SDK 总数 | P1 |
| L2.LS.10 | 大量子项（87 项） | fixture: 87 个子文件夹（采样实际值） | `fz ls /drive/_fz_test_large/` | 所有 87 项列出 | stdout 行数 vs SDK | P1 |
| L2.LS.11 | 深层嵌套路径 | fixture: a/b/c/d（4 层） | `fz ls /drive/_fz_test_root/a/b/c/` | 列出 c 下的内容 | stdout vs SDK | P1 |
| L2.LS.12 | 含 emoji 文件名 | fixture: "📁项目资料" | `fz ls /drive/_fz_test_root/` | emoji 正确显示 | stdout | P2 |
| L2.LS.13 | 超长文件名（41 字符，采样值） | fixture: 41 字符名称 | `fz ls /drive/_fz_test_root/` | 名称完整显示 | stdout | P2 |

#### fz ls — Wiki

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L2.LS.14 | 列出 Wiki 空间列表 | 有可访问的 Wiki 空间 | `fz ls /wiki/` | 输出包含测试空间名 | stdout vs SDK listSpaces() | P0 |
| L2.LS.15 | 列出空间顶层节点 | fixture: 测试空间内有节点 | `fz ls /wiki/龙虾测试环境/` | 列出顶层节点 | stdout vs SDK listNodes() | P0 |
| L2.LS.16 | 列出嵌套节点 | fixture: parent→child | `fz ls /wiki/龙虾测试环境/parent/` | 列出 parent 子节点 | stdout vs SDK | P1 |
| L2.LS.17 | 空 Wiki 空间 | fixture: 无节点的测试空间 | `fz ls /wiki/龙虾测试环境/` | exitCode=0，空输出 | stdout | P1 |
| L2.LS.18 | 不存在的 Wiki 空间 | 无 | `fz ls /wiki/不存在的空间/` | exitCode≠0 | stderr | P0 |
| L2.LS.19 | 显示节点类型区分 | fixture: docx + sheet 节点 | `fz ls /wiki/龙虾测试环境/` | 输出能区分文档类型 | stdout | P1 |
| L2.LS.20 | mindnote 类型节点 | fixture: mindnote 节点 | `fz ls /wiki/龙虾测试环境/` | mindnote 正确显示 | stdout | P2 |
| L2.LS.21 | bitable 类型节点 | fixture: bitable 节点 | `fz ls /wiki/龙虾测试环境/` | bitable 正确显示 | stdout | P2 |

#### fz cat — 网盘

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L2.CAT.01 | 读取 docx 文档 | fixture: 含文本的 docx | `fz cat /drive/test-doc` | exitCode=0，输出文档内容 | stdout vs SDK rawContent | P0 |
| L2.CAT.02 | 读取空文档 | fixture: 空 docx | `fz cat /drive/empty-doc` | exitCode=0，空输出 | stdout | P1 |
| L2.CAT.03 | 不存在的文档 | 无 | `fz cat /drive/nonexistent` | exitCode≠0 | stderr | P0 |
| L2.CAT.04 | cat 文件夹应报错 | fixture: 文件夹 | `fz cat /drive/_fz_test_root/` | exitCode≠0，提示非文档 | stderr | P0 |
| L2.CAT.05 | 中文内容文档 | fixture: 中文 docx | `fz cat /drive/chinese-doc` | 中文正确输出 | stdout | P0 |
| L2.CAT.06 | 富文本文档 | fixture: 标题+列表+代码块 | `fz cat /drive/rich-doc` | 文本内容被提取 | stdout | P1 |
| L2.CAT.07 | cat sheet 类型 | fixture: sheet 文档 | `fz cat /drive/test-sheet` | 合理处理：报错或输出元信息 | stdout/stderr | P1 |

#### fz cat — Wiki

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L2.CAT.08 | 读取 Wiki 文档 | fixture: 含内容的 Wiki 节点 | `fz cat /wiki/龙虾测试环境/test-doc` | exitCode=0，输出内容 | stdout vs SDK | P0 |
| L2.CAT.09 | 不存在的 Wiki 文档 | 无 | `fz cat /wiki/龙虾测试环境/nonexistent` | exitCode≠0 | stderr | P0 |
| L2.CAT.10 | 嵌套路径的 Wiki 文档 | fixture: parent/child | `fz cat /wiki/龙虾测试环境/parent/child` | 正确解析多层路径 | stdout | P1 |
| L2.CAT.11 | cat 非 docx 类型节点 | fixture: sheet 节点 | `fz cat /wiki/龙虾测试环境/a-sheet` | 合理处理 | stdout/stderr | P1 |

---

### 第 3 层：写操作

> 前提：第 1、2 层通过
> 数据策略：**独立数据**——beforeEach 创建父目录，afterEach 清理
> 观测方式：CLI 执行后用 SDK 独立查询确认云端状态

#### fz mkdir — 网盘

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L3.MKDIR.01 | 创建文件夹 | 独立: 创建 _fz_test_root/ | `fz mkdir /drive/_fz_test_root/new` | exitCode=0 | SDK exists() 确认 | P0 |
| L3.MKDIR.02 | 中文名文件夹 | 同上 | `fz mkdir /drive/_fz_test_root/新建文件夹` | exitCode=0 | SDK 确认存在 | P0 |
| L3.MKDIR.03 | 含空格名称 | 同上 | `fz mkdir /drive/_fz_test_root/"my folder"` | exitCode=0 | SDK 确认 | P1 |
| L3.MKDIR.04 | 含括号名称 | 同上 | `fz mkdir /drive/_fz_test_root/"报告(v2)"` | exitCode=0 | SDK 确认 | P1 |
| L3.MKDIR.05 | 重复创建同名 | 已有同名文件夹 | 再次 `fz mkdir` 同名 | 创建成功或提示已存在 | SDK 查同名项数 | P1 |
| L3.MKDIR.06 | 父目录不存在 | 无 | `fz mkdir /drive/nonexistent/child` | exitCode≠0 | stderr | P0 |
| L3.MKDIR.07 | 在根目录创建 | 无额外前置 | `fz mkdir /drive/_fz_test_new_root` | exitCode=0 | SDK 根目录列表确认 | P0 |
| L3.MKDIR.08 | 递归创建 -p | _fz_test_root/ 存在 | `fz mkdir -p .../a/b/c` | 递归创建 | SDK 逐层验证 | P1 |
| L3.MKDIR.09 | 名称为空 | 无 | `fz mkdir /drive/_fz_test_root/` | exitCode≠0 | stderr | P1 |
| L3.MKDIR.10 | 超长名称（300 字符） | 同上 | `fz mkdir /drive/...` + 300 字符 | 合理报错或截断 | stderr/SDK | P2 |
| L3.MKDIR.11 | emoji 名称 | 同上 | `fz mkdir /drive/_fz_test_root/📁新目录` | exitCode=0 | SDK 确认 | P2 |

#### fz mkdir — Wiki

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L3.MKDIR.12 | 顶层创建节点 | 测试空间可用 | `fz mkdir /wiki/龙虾测试环境/new-node` | exitCode=0 | SDK nodeExists() | P0 |
| L3.MKDIR.13 | 创建子节点 | SDK 先创建 parent | `fz mkdir /wiki/.../parent/child` | exitCode=0 | SDK 列出 parent 子节点 | P1 |
| L3.MKDIR.14 | Wiki 空间不存在 | 无 | `fz mkdir /wiki/不存在的/doc` | exitCode≠0 | stderr | P0 |
| L3.MKDIR.15 | 中文节点标题 | 测试空间可用 | `fz mkdir /wiki/龙虾测试环境/新建文档` | exitCode=0 | SDK 确认 | P0 |

---

### 第 4 层：路径系统端到端

> 前提：第 1、2、3 层通过
> 数据策略：**完整生命周期**——每个用例独立管理

#### 路径解析

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L4.PATH.01 | /drive/ 根路径 | 无 | `fz ls /drive/` | 等同列出网盘根目录 | stdout vs SDK | P0 |
| L4.PATH.02 | /wiki/ 根路径 | 无 | `fz ls /wiki/` | 列出所有 Wiki 空间 | stdout vs SDK | P0 |
| L4.PATH.03 | 4 层嵌套（采样值） | SDK 创建 a/b/c/d | `fz ls /drive/.../a/b/c/` | 列出 c 的内容 | stdout vs SDK | P1 |
| L4.PATH.04 | 中文嵌套路径 | SDK 创建 "项目文档/周报" | `fz ls /drive/项目文档/` | 列出"周报" | stdout | P1 |
| L4.PATH.05 | Wiki 3 层嵌套 | SDK 创建 3 层节点 | `fz cat /wiki/.../l1/l2/l3` | 解析到最深层 | stdout | P1 |
| L4.PATH.06 | 末尾有无斜杠等效 | 无 | `fz ls /drive/folder` vs `/drive/folder/` | 输出相同 | 比对两次 stdout | P1 |
| L4.PATH.07 | 无效路径前缀 | 无 | `fz ls /invalid/path` | exitCode≠0，提示无效 | stderr | P0 |
| L4.PATH.08 | 空路径 | 无 | `fz ls` | 显示用法或列出顶层 | stdout/stderr | P1 |
| L4.PATH.09 | 路径中含连续斜杠 | 无 | `fz ls /drive//folder/` | 合理处理 | stdout/stderr | P2 |
| L4.PATH.10 | 路径含 .. | 无 | `fz ls /drive/a/../b/` | 合理处理或报错 | stdout/stderr | P2 |

#### 端到端全链路

| 编号 | 用例名称 | 前置条件 | 触发 | 预期结果 | 观测方式 | 优先级 |
|------|---------|---------|------|---------|---------|-------|
| L4.E2E.01 | 网盘 mkdir→ls→确认 | 无 | mkdir + ls | ls 输出包含新建文件夹 | SDK 独立验证 | P0 |
| L4.E2E.02 | Wiki mkdir→ls→cat | 无 | mkdir + ls + cat | 三步串联成功 | 每步 SDK 验证 | P0 |
| L4.E2E.03 | 跨域操作串联 | 无 | 网盘 mkdir + Wiki mkdir + 两个 ls | 互不干扰 | SDK 分别验证 | P1 |

---

### 跨层：边界与异常

| 编号 | 用例名称 | 触发 | 预期结果 | 优先级 |
|------|---------|------|---------|-------|
| LX.ERR.01 | 无参数运行 | `fz` | 显示用法，exitCode=0 | P0 |
| LX.ERR.02 | 未知子命令 | `fz unknown` | exitCode≠0 | P0 |
| LX.ERR.03 | 网络断开 | 断网后 `fz ls /drive/` | 优雅报错，非 crash | P1 |
| LX.ERR.04 | 超长路径名 | 300 字符路径 | 合理报错 | P2 |
| LX.ERR.05 | 路径含空格 | `fz ls "/drive/my folder/"` | 正确处理 | P1 |
| LX.ERR.06 | API 限流 429 | 短时间高频调用 | 优雅报错或重试 | P2 |
| LX.ERR.07 | token 过期中途失效 | 长时间运行后 token 过期 | 自动刷新或提示 | P2 |

---

## 用户旅程

### 旅程 1：新员工查看团队文档

**角色**：新入职的产品经理
**目标**：找到团队的产品文档并阅读
**前置**：已配置 fz 凭证

| 步骤 | 操作 | 期望结果 | 映射用例 |
|------|------|---------|---------|
| 1 | `fz ls /wiki/` | 看到所有 Wiki 空间列表 | L2.LS.14 |
| 2 | `fz ls /wiki/产品团队/` | 看到产品团队空间的文档列表 | L2.LS.15 |
| 3 | `fz cat /wiki/产品团队/产品需求文档` | 阅读产品需求文档内容 | L2.CAT.08 |
| 4 | `fz ls /drive/` | 查看网盘根目录 | L2.LS.01 |
| 5 | `fz ls /drive/产品部/` | 查看产品部文件夹 | L2.LS.06 |

**优先级**：P0

### 旅程 2：开发者整理项目文档

**角色**：全栈开发者
**目标**：在网盘和 Wiki 中创建项目文档结构
**前置**：已配置 fz 凭证

| 步骤 | 操作 | 期望结果 | 映射用例 |
|------|------|---------|---------|
| 1 | `fz mkdir /drive/项目Alpha/` | 创建项目根文件夹 | L3.MKDIR.02 |
| 2 | `fz mkdir /drive/项目Alpha/设计文档/` | 创建子文件夹 | L3.MKDIR.01 |
| 3 | `fz ls /drive/项目Alpha/` | 确认子文件夹已创建 | L4.E2E.01 |
| 4 | `fz mkdir /wiki/龙虾测试环境/项目Alpha-Wiki` | 在 Wiki 创建对应空间 | L3.MKDIR.12 |
| 5 | `fz ls /wiki/龙虾测试环境/` | 确认 Wiki 节点已创建 | L2.LS.15 |

**优先级**：P0

---

## 维度覆盖矩阵

### ls 命令覆盖

| 用例 | 路径域 | 深度 | 字符集 | 内容量 | 类型 |
|------|--------|------|--------|--------|------|
| L2.LS.01 | /drive/ | 根 | — | 正常 | 混合 |
| L2.LS.02 | /drive/ | 1层 | ASCII | 少量 | 纯文件夹 |
| L2.LS.03 | /drive/ | 1层 | ASCII | 空 | — |
| L2.LS.05 | /drive/ | 1层 | ASCII | 少量 | 混合 |
| L2.LS.06 | /drive/ | 1层 | 中文 | — | — |
| L2.LS.07 | /drive/ | 1层 | 空格 | — | — |
| L2.LS.08 | /drive/ | 1层 | 括号 | — | — |
| L2.LS.09 | /drive/ | 1层 | ASCII | 临界(51) | 纯文件夹 |
| L2.LS.10 | /drive/ | 1层 | ASCII | 大量(87) | 纯文件夹 |
| L2.LS.11 | /drive/ | 4层 | ASCII | — | — |
| L2.LS.14 | /wiki/ | 根 | — | 正常 | — |
| L2.LS.15 | /wiki/ | 1层 | 中文 | 正常 | 混合 |
| L2.LS.16 | /wiki/ | 2层 | — | — | — |

### 未覆盖组合

| 维度对 | 未覆盖 | 处理 |
|--------|--------|------|
| /wiki/ × 大量内容 | Wiki 大量节点的分页 | P2 用例可补充 |
| /wiki/ × 4层嵌套 | Wiki 最大只有 3 层 | 采样发现 Wiki 最深 3 层，已有 L2.LS.16(2层) 和 L4.PATH.05(3层) |
| 特殊字符 × /wiki/ | Wiki 节点含特殊字符 | 已有 L3.MKDIR.15（中文），可补充括号用例 |

---

## 数据蓝图

### 全局数据

| 数据 | 说明 | 来源 |
|------|------|------|
| APP_ID + APP_SECRET | 飞书应用凭证 | .env.test |
| 龙虾测试环境 | 已有的 Wiki 空间 | 环境中已存在 |

### 第 2 层数据（共享 fixture）

| 数据名称 | 类型 | 详情 | 创建方式 | 生命周期 | 被引用用例 | 优先级 |
|---------|------|------|---------|---------|-----------|-------|
| _fz_test_root | 文件夹 | 测试根目录 | SDK createFolder | beforeAll / afterAll | L2.LS.02,06-08 等 | P0 |
| three_folders | 子文件夹×3 | alpha/beta/gamma | SDK ×3 | 随 test_root | L2.LS.02 | P0 |
| empty_folder | 子文件夹 | 空的 _fz_test_empty | SDK | 随 test_root | L2.LS.03 | P0 |
| mixed_folder | 子文件夹 | folder+docx+file | SDK + 上传 | 随 test_root | L2.LS.05 | P0 |
| chinese_folder | 子文件夹 | "测试文件夹" | SDK | 随 test_root | L2.LS.06 | P0 |
| space_folder | 子文件夹 | "my folder" | SDK | 随 test_root | L2.LS.07 | P1 |
| paren_folder | 子文件夹 | "报告(修订版)" | SDK | 随 test_root | L2.LS.08 | P1 |
| many_folders | 文件夹组 | 51 个子文件夹 f001-f051 | SDK 批量创建 | 随 test_root | L2.LS.09 | P1 |
| large_folders | 文件夹组 | 87 个子文件夹 f001-f087 | SDK 批量创建 | 随 test_root | L2.LS.10 | P1 |
| deep_nesting | 4层嵌套 | a/b/c/d | SDK 递归 | 随 test_root | L2.LS.11, L4.PATH.03 | P1 |
| emoji_folder | 子文件夹 | "📁项目资料" | SDK | 随 test_root | L2.LS.12 | P2 |
| long_name_folder | 子文件夹 | 41字符名（采样值） | SDK | 随 test_root | L2.LS.13 | P2 |
| test_docx | 文档 | 含文本内容的 docx | SDK 创建文档 | 随 test_root | L2.CAT.01 | P0 |
| empty_docx | 文档 | 空 docx | SDK | 随 test_root | L2.CAT.02 | P1 |
| chinese_docx | 文档 | 含中文内容 | SDK | 随 test_root | L2.CAT.05 | P0 |
| rich_docx | 文档 | 标题+列表+代码块 | SDK | 随 test_root | L2.CAT.06 | P1 |
| test_sheet | 文档 | sheet 类型 | SDK | 随 test_root | L2.CAT.07 | P1 |
| wiki_test_nodes | Wiki 节点×N | 各种类型节点 | SDK | beforeAll / afterAll | L2.LS.15-21, L2.CAT.08-11 | P0 |
| wiki_nested | Wiki 嵌套 | parent→child | SDK | 随 wiki_test_nodes | L2.LS.16, L2.CAT.10 | P1 |

### 生命周期

```
第 1 层：无数据
第 2 层：beforeAll 创建全部 fixture → 所有只读用例复用 → afterAll 清理
第 3 层：beforeEach 创建 _fz_test_root/ → 用例执行 mkdir → afterEach SDK 清理
第 4 层：每个用例完整管理（创建→操作→验证→清理）
```

### 数据量统计

| 优先级 | 数据项数 | 说明 |
|--------|---------|------|
| P0 | 8 项 | 根目录、基本文件夹(3)、空目录、混合目录、中文名、文档、Wiki 节点 |
| P1 | 11 项 | 空格名、括号名、分页组(51个)、大量组(87个)、嵌套、空docx、富文本、sheet、Wiki 嵌套等 |
| P2 | 2 项 | emoji、超长名称 |
| **总计** | **21 项** | 不含第 3/4 层动态创建的临时数据，也不含 many/large 组中的单个子文件夹 |

> 注：many_folders(51个) 和 large_folders(87个) 各算 1 个数据项（一次批量创建），实际创建的文件夹数量为 138 个。

### 脚手架衔接

| 蓝图操作 | 脚手架函数 | 状态 |
|---------|-----------|------|
| SDK 创建文件夹 | data-factory.createTestFolder() | ✅ 已支持 |
| SDK 创建子文件夹 | data-factory.createSubFolder() | ✅ 已支持 |
| SDK 创建 Wiki 节点 | data-factory.createTestWikiNode() | ✅ 已支持 |
| SDK 清理网盘 | data-cleanup.cleanupAll() (drive) | ✅ 已支持 |
| SDK 清理 Wiki | data-cleanup.cleanupAll() (wiki→trash) | ✅ 已支持 |
| SDK 创建 docx 文档 | — | ❌ **需扩展** data-factory |
| SDK 上传文件 | — | ❌ **需扩展** data-factory |
| SDK 创建 sheet/bitable | — | ❌ **需扩展** data-factory |

---

## 用例统计

### 按层统计

| 层 | 功能 | P0 | P1 | P2 | 合计 |
|----|------|----|----|-----|------|
| 第 1 层 认证 | auth | 5 | 1 | 0 | 6 |
| 第 2 层 只读 | ls（网盘） | 5 | 6 | 2 | 13 |
| 第 2 层 只读 | ls（Wiki） | 3 | 3 | 2 | 8 |
| 第 2 层 只读 | cat（网盘） | 4 | 3 | 0 | 7 |
| 第 2 层 只读 | cat（Wiki） | 2 | 2 | 0 | 4 |
| 第 3 层 写操作 | mkdir（网盘） | 3 | 5 | 3 | 11 |
| 第 3 层 写操作 | mkdir（Wiki） | 3 | 1 | 0 | 4 |
| 第 4 层 路径 | 路径解析 | 3 | 5 | 2 | 10 |
| 第 4 层 路径 | 端到端 | 2 | 1 | 0 | 3 |
| 跨层 | 异常边界 | 2 | 2 | 3 | 7 |
| **合计** | | **32** | **29** | **12** | **73** |

### 按执行批次

| 批次 | 用例数 | 数据项 | 预估耗时 |
|------|--------|--------|---------|
| @smoke (P0) | 32 | 8 项（实际 ~15 个资源） | ~2 分钟 |
| @regression (P0+P1) | 61 | 19 项（实际 ~160 个资源） | ~5 分钟 |
| @full (全部) | 73 | 21 项（实际 ~162 个资源） | ~8 分钟 |
