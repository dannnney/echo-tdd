# 示例：桌面应用

## 维度组合

| 维度 | 值 |
|------|-----|
| 需求 | 测试文件导入和编辑功能 |
| 代码仓库 | Electron 桌面应用（TypeScript + React） |
| 服务端 | 无独立服务端（Electron 内嵌） |
| 数据库 | 本地 SQLite，可清空 |
| 前端 | Electron 窗口（本地） |
| 验证通道 | 桌面自动化（mac-use）+ 文件系统 + 本地 DB |
| 认证 | 不需要认证（本地应用） |
| 数据策略 | 可以清空重建（删除本地 SQLite 文件） |

## 生成的测试方案要点

- 启动方式：`npm run electron:dev`
- 桌面自动化验证：使用 mac-use skill 控制 Electron 窗口
  - 点击"导入文件"按钮
  - 选择测试文件
  - 验证文件出现在列表中
- 文件系统验证：检查 `~/Library/Application Support/MyApp/` 下的文件
- DB 验证：`sqlite3 ~/Library/Application\ Support/MyApp/data.db "SELECT * FROM files"`
- 数据准备：删除本地 DB 文件重新启动（自动创建空 DB）
- 认证：不需要

## 环境前置条件

- [ ] Node.js 和 npm 可用
- [ ] Electron 应用可启动：`npm run electron:dev`
- [ ] mac-use skill 可用（macOS 环境）
- [ ] 测试文件准备好（用于导入测试）
