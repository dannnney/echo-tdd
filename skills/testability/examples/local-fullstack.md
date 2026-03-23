# 示例：全部本地全栈开发

## 维度组合

| 维度 | 值 |
|------|-----|
| 需求 | 测试用户注册和登录流程 |
| 代码仓库 | Next.js 全栈应用（TypeScript + Prisma + PostgreSQL） |
| 服务端 | 本地可运行（`npm run dev`） |
| 数据库 | 本地 Docker PostgreSQL，可清空 |
| 前端 | 本地开发可运行（同一 repo） |
| 验证通道 | 浏览器 + DB CLI + API |
| 认证 | 可以自注册（项目有完整注册流程） |
| 数据策略 | 可以清空重建（`prisma migrate reset`） |

## 生成的测试方案要点

- 启动方式：`docker compose up -d db && npm run dev`
- 浏览器验证：Playwright 打开 `http://localhost:3000/register`，填写表单注册
- DB 验证：`psql -h localhost -U postgres -d mydb -c "SELECT * FROM users WHERE email='test@test.com'"`
- API 验证：`curl http://localhost:3000/api/auth/session`
- 数据准备：`npx prisma migrate reset --force` 清空后 `npx prisma db seed` 填充基础数据
- 认证：通过浏览器自动注册获取登录态

## 环境前置条件

- [ ] Docker 运行中，PostgreSQL 容器启动
- [ ] `npm run dev` 服务正常启动在 3000 端口
- [ ] 浏览器可访问 http://localhost:3000
- [ ] psql 可连接本地数据库
