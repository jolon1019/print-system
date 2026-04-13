# 热卷打印管理系统 - 数据库说明文档

## 概述

本系统使用 PostgreSQL / Supabase 数据库，数据库初始化脚本为 `database_init_complete.sql`。

## 数据库表结构

### 一、用户系统

| 表名 | 说明 |
|------|------|
| users | 用户表 - 存储用户账号信息 |
| user_units | 用户单位绑定表 - 用户与单位的关联关系 |

**users 表字段：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 用户ID（主键） |
| username | VARCHAR(50) | 用户名（唯一） |
| password | VARCHAR(255) | 密码（bcrypt加密） |
| real_name | VARCHAR(50) | 真实姓名 |
| role | VARCHAR(20) | 角色：admin/user |
| status | SMALLINT | 状态：1-启用，0-禁用 |

**默认账号：** admin/user1/user2，密码均为 `123456`

---

### 二、核心业务表

| 表名 | 说明 |
|------|------|
| inventory | 库存主表 - 热卷入库记录 |
| outbound | 出库记录表 - 出库业务记录 |
| team_notes | 团队备注表 - 团队协作备注 |
| inventory_transfer | 货权转让表 - 货权转让记录 |

**inventory 表字段：**
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | 主键 |
| batch_no | VARCHAR(50) | 批号（唯一） |
| unit | VARCHAR(20) | 单位 |
| specification | VARCHAR(100) | 规格 |
| material | VARCHAR(50) | 材料类型 |
| weight | DECIMAL(15,3) | 入库重量 |
| storage_location | VARCHAR(100) | 存储位置 |
| in_date | DATE | 入库日期 |
| status | SMALLINT | 状态：1-在库，2-已出库，3-冻结 |

**outbound 表字段：**
| 字段 | 类型 | 说明 |
|------|------|------|
| outbound_order_id | BIGSERIAL | 主键 |
| inventory_id | BIGINT | 关联库存ID |
| batch_no | VARCHAR(50) | 批号 |
| out_weight | DECIMAL(15,3) | 出库重量 |
| unit_price | DECIMAL(10,2) | 单价 |
| total_amount | DECIMAL(12,2) | 总金额 |
| out_type | SMALLINT | 出库类型：1-加工，2-装卷，3-销售，4-货权转让 |
| out_date | DATE | 出库日期 |
| ref_no | TEXT | 出库单号 |

---

### 三、财务系统表

| 表名 | 说明 |
|------|------|
| finance_ledger | 财务台账表 - 收支记录 |
| daily_accounting | 日常记账表 - 每日账务汇总 |
| accounting_subjects | 会计科目表 - 会计科目定义 |
| income_expense_categories | 收支分类表 - 收支分类定义 |
| reconciliation_records | 对账记录表 - 对账确认记录 |
| accounting_vouchers | 会计凭证表 - 凭证主表 |
| voucher_items | 凭证明细表 - 凭证分录明细 |
| financial_summary | 财务汇总表 - 财务报表汇总 |

---

## 视图

| 视图名 | 说明 |
|------|------|
| current_inventory | 当前有效库存视图 - 筛选状态为在库的库存 |
| outbound_summary | 出库统计视图 - 出库记录与库存关联查询 |

---

## 触发器

| 触发器名 | 说明 |
|------|------|
| update_users_updated_at | 用户表更新时间自动更新 |
| update_team_notes_updated_at | 团队备注表更新时间自动更新 |
| update_inventory_transfer_updated_at | 货权转让表更新时间自动更新 |
| after_outbound_insert | 出库后自动更新库存状态（货权转让除外） |

---

## 使用方法

1. 在 Supabase 或 PostgreSQL 中执行 `database_init_complete.sql`
2. 脚本会自动创建所有表、索引、触发器和视图
3. 默认用户数据会自动插入

## 注意事项

- 所有密码使用 bcrypt 加密存储
- 出库类型4（货权转让）不会改变库存状态
- 表使用 `IF NOT EXISTS` 确保可重复执行
