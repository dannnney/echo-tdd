# 示例：纯 API 服务 + 无前端

## 维度组合

| 维度 | 值 |
|------|-----|
| 需求 | 测试 CRUD API 和权限控制 |
| 代码仓库 | Go + Gin 后端 API 服务 |
| 服务端 | 本地可运行（`go run main.go`） |
| 数据库 | 远程 PostgreSQL（dev 环境），可读写 |
| 前端 | 无前端 |
| 验证通道 | API + DB CLI |
| 认证 | 可以自注册（有 `/api/register` 端点） |
| 数据策略 | 只能追加（远程 DB 不建议清空） |

## 生成的测试方案要点

- 启动方式：`go run main.go`（确保 `.env` 配置远程 DB）
- API 验证：
  - 注册：`curl -X POST http://localhost:8080/api/register -d '{"email":"test@test.com","password":"test123"}'`
  - 登录获取 token：`curl -X POST http://localhost:8080/api/login -d '{"email":"test@test.com","password":"test123"}'`
  - CRUD 操作：`curl -H "Authorization: Bearer <token>" http://localhost:8080/api/resources`
- DB 验证：`psql -h dev-db.example.com -U devuser -d mydb -c "SELECT * FROM resources WHERE created_by='test@test.com'"`
- 数据准备：通过 API 注册用户 + 创建测试数据
- 数据清理：测试结束后通过 API 或 DB 删除测试用户创建的数据（`DELETE FROM resources WHERE created_by='test@test.com'`）

## 环境前置条件

- [ ] Go 环境可用：`go version`
- [ ] 服务启动正常：`curl http://localhost:8080/health`
- [ ] 远程 DB 可连接且可写：`psql -h dev-db.example.com -U devuser -d mydb -c "SELECT 1"`
- [ ] 注册 API 可用：`curl -X POST http://localhost:8080/api/register -d '...'`
