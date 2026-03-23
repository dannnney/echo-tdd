# 示例：前端本地 + 远程 API

## 维度组合

| 维度 | 值 |
|------|-----|
| 需求 | 测试商品搜索和筛选功能 |
| 代码仓库 | React SPA（TypeScript + Vite） |
| 服务端 | 远程 dev 环境 API（https://api-dev.example.com） |
| 数据库 | 无访问权限（API 团队管理） |
| 前端 | 本地开发可运行，proxy 连远程 API |
| 验证通道 | 浏览器 + API（通过远程 dev 环境） |
| 认证 | Cookie 导入（公司 SSO 登录太复杂） |
| 数据策略 | 只能用现有数据（无 DB 访问） |

## 生成的测试方案要点

- 启动方式：`npm run dev`（Vite proxy 自动转发 API 请求到远程）
- 浏览器验证：Playwright 打开 `http://localhost:5173/products`，搜索关键词，验证结果列表
- API 验证：`curl https://api-dev.example.com/api/products?q=keyword -H "Cookie: <auth_cookie>"`
- 数据准备：使用远程 dev 环境中已有的商品数据
- 认证：
  1. 用户在浏览器中手动登录 SSO
  2. 导出 cookie（`document.cookie` 或浏览器开发工具）
  3. 导入到 Playwright 的 storage state

## 环境前置条件

- [ ] 远程 dev API 可达：`curl -s -o /dev/null -w "%{http_code}" https://api-dev.example.com/health`
- [ ] 前端 dev server 启动：`curl -s -o /dev/null -w "%{http_code}" http://localhost:5173`
- [ ] 认证 cookie 有效：`curl -H "Cookie: <cookie>" https://api-dev.example.com/api/me`
- [ ] API proxy 配置正确：在前端页面中调用 API 能正常返回数据
