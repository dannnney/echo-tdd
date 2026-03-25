# 示例：fz CLI 项目的阶段二产出

基于 fz 项目的 test-strategy-v3.md 策略文档（阶段一产出）。

---

## Phase 0: 策略解析摘要

| 来源 | 提取内容 |
|------|---------|
| 技术栈 | Node.js / TypeScript，CLI 工具 |
| 可观测性 | 触发：CLI 命令；观测：飞书 SDK + 应用凭证（独立通道） |
| 认证 | 飞书应用凭证（App ID + App Secret → tenant_access_token） |
| 数据流闭环 | SDK 创建 → CLI 执行 → SDK 验证 → SDK 清理 |
| 前置条件 | 7 项 checklist |

---

## Phase 1-2: 探测报告

```
## 环境探测报告

| # | 探测项 | 状态 | 详情 |
|---|--------|------|------|
| 1 | Node.js ≥18 | ✅ PASS | v20.11.0 |
| 2 | 飞书 SDK 可安装 | ✅ PASS | @larksuiteoapi/node-sdk@3.4.2 |
| 3 | 应用凭证有效 | ✅ PASS | tenant_access_token 获取成功 (t-g10xxx...) |
| 4 | 网盘 API 权限 | ✅ PASS | drive.v1.file.listByFolder 返回 200 |
| 5 | Wiki API 权限 | ✅ PASS | wiki.v2.space.list 返回 200 |
| 6 | 可创建测试文件夹 | ✅ PASS | _fz_test_probe/ 创建并删除成功 |
| 7 | 可创建 Wiki 空间 | ✅ PASS | _fz_test_wiki_probe 创建并删除成功 |

通过: 7/7 | 失败: 0/7

所有前置条件满足，无需策略调整。
```

---

## Phase 3: 脚手架代码

### 文件结构

```
test/
├── helpers/
│   ├── auth.ts           ← 飞书认证 helper
│   ├── feishu-client.ts  ← 飞书 SDK 封装（观测通道客户端）
│   ├── data-factory.ts   ← 测试数据创建工厂
│   └── data-cleanup.ts   ← 测试数据清理
├── smoke.test.ts         ← Smoke test
├── setup.ts              ← 全局 setup/teardown
├── vitest.config.ts      ← Vitest 配置
└── .env.test             ← 环境变量模板
```

### `test/helpers/auth.ts`

```typescript
import * as lark from '@larksuiteoapi/node-sdk';

let cachedClient: lark.Client | null = null;

/**
 * 获取已认证的飞书 SDK Client
 * 使用应用凭证自动获取 tenant_access_token
 */
export function getFeishuClient(): lark.Client {
  if (cachedClient) return cachedClient;

  const appId = process.env.FEISHU_APP_ID;
  const appSecret = process.env.FEISHU_APP_SECRET;

  if (!appId || !appSecret) {
    throw new Error('缺少 FEISHU_APP_ID 或 FEISHU_APP_SECRET，请检查 .env.test');
  }

  cachedClient = new lark.Client({
    appId,
    appSecret,
    appType: lark.AppType.SelfBuild,
  });

  return cachedClient;
}

/**
 * 验证认证是否有效
 */
export async function verifyAuth(): Promise<boolean> {
  const client = getFeishuClient();
  try {
    // 最小 API 调用验证 token 有效
    const res = await client.drive.v1.file.list({
      params: { folder_token: 'root', page_size: 1 },
    });
    return res.code === 0;
  } catch {
    return false;
  }
}
```

### `test/helpers/feishu-client.ts`

```typescript
import * as lark from '@larksuiteoapi/node-sdk';
import { getFeishuClient } from './auth';

/**
 * 网盘操作 —— 独立观测通道
 * 用于验证 CLI 操作结果，不通过 fz 自身
 */
export const drive = {
  /** 列出文件夹内容 */
  async listFolder(folderToken: string) {
    const client = getFeishuClient();
    const res = await client.drive.v1.file.list({
      params: { folder_token: folderToken },
    });
    if (res.code !== 0) throw new Error(`listFolder 失败: ${res.msg}`);
    return res.data?.files ?? [];
  },

  /** 创建文件夹 */
  async createFolder(name: string, parentToken: string) {
    const client = getFeishuClient();
    const res = await client.drive.v1.file.createFolder({
      data: { name, folder_token: parentToken },
    });
    if (res.code !== 0) throw new Error(`createFolder 失败: ${res.msg}`);
    return res.data?.token!;
  },

  /** 删除文件/文件夹 */
  async delete(fileToken: string, type: string = 'folder') {
    const client = getFeishuClient();
    const res = await client.drive.v1.file.delete({
      path: { file_token: fileToken },
      params: { type },
    });
    if (res.code !== 0) throw new Error(`delete 失败: ${res.msg}`);
  },

  /** 检查文件/文件夹是否存在 */
  async exists(folderToken: string, name: string): Promise<boolean> {
    const files = await this.listFolder(folderToken);
    return files.some((f: any) => f.name === name);
  },
};

/**
 * Wiki 操作 —— 独立观测通道
 */
export const wiki = {
  /** 列出 Wiki 空间 */
  async listSpaces() {
    const client = getFeishuClient();
    const res = await client.wiki.v2.space.list();
    if (res.code !== 0) throw new Error(`listSpaces 失败: ${res.msg}`);
    return res.data?.items ?? [];
  },

  // ... 更多 Wiki 操作
};
```

### `test/helpers/data-factory.ts`

```typescript
import { drive, wiki } from './feishu-client';

const TEST_PREFIX = '_fz_test_';

/** 已创建的测试资源，供清理使用 */
const createdResources: Array<{ type: string; token: string }> = [];

/**
 * 创建测试文件夹（在网盘根目录下）
 */
export async function createTestFolder(name?: string): Promise<{ token: string; name: string }> {
  const folderName = name ?? `${TEST_PREFIX}${Date.now()}`;
  const rootToken = process.env.FEISHU_TEST_ROOT_FOLDER ?? 'root';
  const token = await drive.createFolder(folderName, rootToken);
  createdResources.push({ type: 'folder', token });
  return { token, name: folderName };
}

/**
 * 在指定文件夹下创建子文件夹
 */
export async function createSubFolder(parentToken: string, name: string): Promise<string> {
  const token = await drive.createFolder(name, parentToken);
  createdResources.push({ type: 'folder', token });
  return token;
}

/**
 * 获取已创建的所有测试资源（供清理使用）
 */
export function getCreatedResources() {
  return [...createdResources];
}
```

### `test/helpers/data-cleanup.ts`

```typescript
import { drive } from './feishu-client';
import { getCreatedResources } from './data-factory';

/**
 * 清理所有通过 data-factory 创建的测试资源
 * 按创建的逆序清理（先清子资源再清父资源）
 */
export async function cleanupAll(): Promise<void> {
  const resources = getCreatedResources().reverse();

  for (const resource of resources) {
    try {
      await drive.delete(resource.token, resource.type);
    } catch (err) {
      // 清理失败不阻塞，打 warning
      console.warn(`清理失败 [${resource.type}:${resource.token}]:`, (err as Error).message);
    }
  }
}
```

### `test/smoke.test.ts`

```typescript
import { describe, it, expect, afterAll } from 'vitest';
import { verifyAuth } from './helpers/auth';
import { drive } from './helpers/feishu-client';
import { createTestFolder } from './helpers/data-factory';
import { cleanupAll } from './helpers/data-cleanup';

afterAll(async () => {
  await cleanupAll();
});

describe('Smoke Test — 脚手架链路验证', () => {
  it('认证 → 创建 → 验证 → 清理', async () => {
    // 1. 认证
    const authOk = await verifyAuth();
    expect(authOk).toBe(true);

    // 2. 数据创建
    const folder = await createTestFolder();
    expect(folder.token).toBeTruthy();

    // 3. 独立通道验证（SDK 直查）
    const rootToken = process.env.FEISHU_TEST_ROOT_FOLDER ?? 'root';
    const exists = await drive.exists(rootToken, folder.name);
    expect(exists).toBe(true);

    // 4. 清理
    await cleanupAll();

    // 5. 验证清理成功
    const stillExists = await drive.exists(rootToken, folder.name);
    expect(stillExists).toBe(false);
  }, 30_000); // 30 秒超时
});
```

### `test/setup.ts`

```typescript
import dotenv from 'dotenv';
import path from 'path';

// 加载测试环境变量
dotenv.config({ path: path.resolve(__dirname, '.env.test') });
```

### `test/vitest.config.ts`

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    setupFiles: ['./test/setup.ts'],
    testTimeout: 30_000,       // 单个测试 30 秒
    hookTimeout: 60_000,       // setup/teardown 60 秒
    globals: true,
  },
});
```

### `test/.env.test`

```bash
# 飞书应用凭证
FEISHU_APP_ID=your_app_id_here
FEISHU_APP_SECRET=your_app_secret_here

# 测试根文件夹 token（可选，默认 root）
# FEISHU_TEST_ROOT_FOLDER=fldcnXXXXXX
```

---

## Phase 4: Smoke Test 结果

```
$ npx vitest run test/smoke.test.ts

 ✓ test/smoke.test.ts (1)
   ✓ Smoke Test — 脚手架链路验证 (1)
     ✓ 认证 → 创建 → 验证 → 清理 (2847ms)

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  15:03:21
   Duration  3.42s

脚手架验证通过。可以进入阶段三（测试用例生成）。
```

---

## 完成总结

| 产出 | 内容 |
|------|------|
| 探测报告 | 7/7 通过，环境就绪 |
| 认证 helper | 飞书 App 凭证 → tenant_access_token，带缓存 |
| 通道客户端 | 飞书 SDK 封装（drive + wiki），独立于 fz CLI |
| 数据工厂 | 创建测试文件夹/子文件夹，_fz_test_ 前缀隔离 |
| 数据清理 | 逆序清理所有测试资源，失败不阻塞 |
| Smoke test | 认证→创建→验证→清理 全链路通过 |
