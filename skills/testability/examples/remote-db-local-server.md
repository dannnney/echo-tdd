# 示例：远程数据库 + 本地服务

## 维度组合

| 维度 | 值 |
|------|-----|
| 需求 | 测试订单创建 API |
| 代码仓库 | Express.js 后端服务（TypeScript + TypeORM + MySQL） |
| 服务端 | 本地可运行（`npm start`），连接远程 dev 数据库 |
| 数据库 | 远程 MySQL（dev 环境），只读权限 |
| 前端 | 无前端（纯 API 服务） |
| 验证通道 | API + DB CLI（只读查询） |
| 认证 | 用户提供测试账号的 JWT token |
| 数据策略 | 只能用现有数据 + 通过 API 创建测试数据 |

## 生成的测试方案要点

- 启动方式：`npm start`（确保 `.env` 中 DB 连接指向 dev 环境）
- API 验证：`curl -X POST http://localhost:4000/api/orders -H "Authorization: Bearer <token>" -d '{"productId": "..."}'`
- DB 验证：`mysql -h dev-db.example.com -u readonly -p -e "SELECT * FROM orders ORDER BY id DESC LIMIT 5"`
- 数据准备：通过 API 调用创建测试数据（不能直接操作数据库）
- 认证：用户提前提供有效的 JWT token

## 环境前置条件

- [ ] 远程 dev 数据库可连接：`mysql -h dev-db.example.com -u readonly -p -e "SELECT 1"`
- [ ] 本地服务启动正常：`curl http://localhost:4000/health`
- [ ] JWT token 有效：`curl -H "Authorization: Bearer <token>" http://localhost:4000/api/me`
