# 用户权限控制系统使用说明

## 概述
本系统为热卷管理系统添加了用户权限控制功能，允许特定用户仅查看其绑定的单位名称下的货物信息。

## 功能特性
- ✅ 用户名密码登录认证
- ✅ 用户与单位绑定
- ✅ 基于单位的数据过滤
- ✅ 查看库存信息
- ✅ 查看出库记录
- ✅ 数据导出功能（Excel格式）
- ✅ 响应式设计，支持移动端

## 安装步骤

### 1. 执行数据库脚本
在 Supabase 数据库中执行 `user_tables.sql` 脚本：

```bash
# 在 Supabase SQL 编辑器中执行
user_tables.sql
```

该脚本会创建以下表：
- `users` - 用户表
- `user_units` - 用户单位绑定表

### 2. 配置 Supabase 连接
在以下文件中替换 Supabase URL 和密钥：

**login.html** 和 **user-view.html** 中：
```javascript
const supabase = createClient(
    'YOUR_SUPABASE_URL',      // 替换为您的 Supabase URL
    'YOUR_SUPABASE_ANON_KEY'  // 替换为您的 Supabase 匿名密钥
);
```

### 3. 创建测试用户
数据库脚本中已包含测试用户：

| 用户名 | 密码 | 真实姓名 | 角色 | 绑定单位 |
|--------|------|----------|------|----------|
| admin | 123456 | 系统管理员 | admin | 无 |
| user1 | 123456 | 张三 | user | 单位A, 单位B |
| user2 | 123456 | 李四 | user | 单位C |

**注意**：测试用户的密码需要使用 bcrypt 加密。在生产环境中，请使用以下 Node.js 代码生成加密密码：

```javascript
const bcrypt = require('bcrypt');
const password = '123456';
const hash = bcrypt.hashSync(password, 10);
console.log(hash);
```

### 4. 添加新用户
在 Supabase 中执行以下 SQL 添加新用户：

```sql
-- 添加用户
INSERT INTO public.users (username, password, real_name, role, status)
VALUES ('新用户名', '$2b$10$加密后的密码', '真实姓名', 'user', 1);

-- 为用户绑定单位
INSERT INTO public.user_units (user_id, unit)
SELECT id, '单位名称' FROM public.users WHERE username = '新用户名';
```

## 使用方法

### 方式一：从主系统登录
1. 启动热卷管理系统
2. 在左侧导航栏点击"用户登录"
3. 输入用户名和密码
4. 登录成功后自动跳转到货物信息查看页面

### 方式二：直接访问登录页面
在浏览器中打开 `login.html` 文件

## 页面功能说明

### 登录页面 (login.html)
- 用户名输入框
- 密码输入框（支持显示/隐藏）
- 表单验证
- 错误提示
- 返回首页链接

### 货物信息查看页面 (user-view.html)

#### 库存信息标签页
- **统计卡片**：显示总批次数、总重量、在库批次数、已出库批次数
- **搜索功能**：支持按批号、材质、规格搜索
- **数据表格**：显示库存详细信息
- **导出功能**：将库存数据导出为 Excel 文件
- **刷新功能**：重新加载数据

#### 出库记录标签页
- **搜索功能**：支持按批号、车号、材质搜索
- **数据表格**：显示出库记录详细信息
- **导出功能**：将出库记录导出为 Excel 文件
- **刷新功能**：重新加载数据

#### 顶部导航
- 显示当前登录用户信息
- 显示用户绑定的单位列表
- 退出登录按钮

## 数据权限说明

### 权限过滤逻辑
系统根据用户绑定的单位过滤数据：

1. **库存信息**：只显示 `inventory` 表中 `unit` 字段在用户绑定单位列表中的记录
2. **出库记录**：只显示 `outbound` 表中关联的 `inventory` 记录的 `unit` 字段在用户绑定单位列表中的记录

### 数据库表关系
```
users (用户表)
  ↓ 1:N
user_units (用户单位绑定表)
  ↓ N:1
inventory (库存表) - 通过 unit 字段关联
  ↓ 1:N
outbound (出库表) - 通过 inventory_id 关联
```

## 技术栈
- **前端框架**：Vue 3
- **UI 组件库**：Element Plus
- **数据库**：Supabase (PostgreSQL)
- **桌面应用**：Electron
- **Excel 导出**：SheetJS (xlsx)

## 安全建议

1. **密码加密**：生产环境中必须使用 bcrypt 加密用户密码
2. **HTTPS**：在生产环境中使用 HTTPS 协议
3. **会话管理**：建议实现会话超时机制
4. **输入验证**：所有用户输入都应进行验证和清理
5. **SQL 注入防护**：使用参数化查询（Supabase SDK 已提供）
6. **访问控制**：在数据库层面也实施行级安全策略（RLS）

## 故障排除

### 问题：登录失败
- 检查用户名和密码是否正确
- 确认 Supabase 连接配置正确
- 检查用户状态是否为启用（status = 1）

### 问题：无法查看数据
- 确认用户已绑定单位
- 检查库存数据中是否存在对应单位的数据
- 查看 Supabase 日志确认查询是否成功

### 问题：导出功能不工作
- 确认已加载 xlsx 库
- 检查浏览器是否支持文件下载

## 文件清单
- `user_tables.sql` - 数据库表创建脚本
- `login.html` - 用户登录页面
- `user-view.html` - 货物信息查看页面
- `main.js` - Electron 主进程（已更新）
- `index.html` - 主页面（已更新）
- `renderer.js` - 渲染进程脚本（已更新）

## 后续扩展建议
1. 添加用户管理界面（增删改查用户）
2. 实现密码修改功能
3. 添加角色权限管理
4. 实现操作日志记录
5. 添加数据可视化图表
6. 支持多语言切换
7. 添加打印功能
8. 实现数据导入功能

## 联系支持
如有问题，请联系系统管理员。
