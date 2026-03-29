# 快速设置指南

## 🚀 5分钟快速配置

### 第一步：执行数据库脚本（1分钟）

在 Supabase 的 SQL 编辑器中执行以下脚本：

**推荐使用**：`user_tables_with_real_hash.sql`（包含真实 bcrypt 密码哈希）

**测试账号**：
- 用户名：`admin`，密码：`123456`
- 用户名：`user1`，密码：`123456`（绑定单位：单位A、单位B）
- 用户名：`user2`，密码：`123456`（绑定单位：单位C）

### 第二步：验证数据库（1分钟）

在 Supabase Table Editor 中检查：

1. **users 表**应该有3条记录
2. **user_units 表**应该有3条记录：
   - user1 绑定了 单位A 和 单位B
   - user2 绑定了 单位C

### 第三步：测试登录（2分钟）

1. 启动热卷管理系统
2. 点击左侧导航栏的"用户登录"
3. 使用测试账号登录：
   - 用户名：`user1`
   - 密码：`123456`
4. 登录成功后会跳转到货物信息查看页面

### 第四步：验证数据权限（1分钟）

登录后检查：
- ✅ 只能看到"单位A"和"单位B"的库存数据
- ✅ 只能看到"单位A"和"单位B"的出库记录
- ✅ 可以导出数据为 Excel

## 📋 数据库表说明

### users 表（用户表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigserial | 用户ID（主键） |
| username | varchar(50) | 用户名（唯一） |
| password | varchar(255) | 密码（bcrypt加密） |
| real_name | varchar(50) | 真实姓名 |
| role | varchar(20) | 角色（admin/user） |
| status | smallint | 状态（1-启用，0-禁用） |
| created_at | timestamp | 创建时间 |
| updated_at | timestamp | 更新时间 |

### user_units 表（用户单位绑定表）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigserial | 绑定ID（主键） |
| user_id | bigint | 用户ID（外键） |
| unit | varchar(50) | 单位名称 |
| created_at | timestamp | 创建时间 |

## 🔧 添加新用户

### 方法一：直接在 Supabase 中添加

1. 在 **users** 表中插入新用户：
```sql
INSERT INTO public.users (username, password, real_name, role, status)
VALUES ('新用户', '$2b$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', '真实姓名', 'user', 1);
```

2. 在 **user_units** 表中绑定单位：
```sql
INSERT INTO public.user_units (user_id, unit)
SELECT id, '单位名称' FROM public.users WHERE username = '新用户';
```

### 方法二：使用 Node.js 生成密码哈希

运行以下脚本生成加密密码：

```bash
node generate-password-hash.js
```

然后将生成的哈希值插入数据库。

## 🎯 常见问题

### Q: 登录时提示"用户名或密码错误"？
A: 检查以下几点：
1. 确认用户名和密码是否正确
2. 确认用户状态为启用（status = 1）
3. 确认 Supabase 连接配置正确

### Q: 登录成功但看不到数据？
A: 检查以下几点：
1. 确认用户已绑定单位
2. 确认 inventory 表中存在对应单位的数据
3. 打开浏览器控制台查看是否有错误

### Q: 如何修改用户密码？
A: 需要生成新的 bcrypt 哈希：
```javascript
const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('新密码', 10);
console.log(hash);
```

然后将哈希值更新到 users 表的 password 字段。

### Q: 如何为用户添加更多单位？
A: 在 user_units 表中插入新记录：
```sql
INSERT INTO public.user_units (user_id, unit)
SELECT id, '新单位名称' FROM public.users WHERE username = '用户名';
```

## 📊 数据权限说明

系统根据用户绑定的单位过滤数据：

- **库存信息**：只显示 `inventory` 表中 `unit` 字段在用户绑定单位列表中的记录
- **出库记录**：只显示 `outbound` 表中关联的 `inventory` 记录的 `unit` 字段在用户绑定单位列表中的记录

## 🔐 安全建议

1. **修改默认密码**：首次登录后立即修改默认密码
2. **定期更换密码**：建议每3个月更换一次密码
3. **使用强密码**：密码长度至少8位，包含大小写字母、数字和特殊字符
4. **限制登录尝试**：建议实现登录失败次数限制
5. **启用 HTTPS**：生产环境必须使用 HTTPS

## 📞 技术支持

如遇到问题，请检查：
1. 浏览器控制台是否有错误信息
2. Supabase 日志中的查询记录
3. 网络连接是否正常
