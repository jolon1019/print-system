# 热卷打印管理系统 - 数据库说明文档

## 概述

本系统使用 PostgreSQL / Supabase 数据库。数据库脚本按编号顺序执行，确保表结构和依赖关系正确建立。

## SQL 脚本执行顺序

| 顺序 | 文件名 | 说明 |
|------|--------|------|
| 1 | `database_01_init_complete.sql` | 核心初始化：用户系统、库存、出库、财务基础、货权转让、虚拟库存 |
| 2 | `database_02_sales_accounting.sql` | 销售与会计核算：客户、订单、报价、银行账户、应收/应付 |
| 3 | `database_03_extended.sql` | 扩展功能：供应商、成本核算、税务管理、期末结账 |
| 4 | `database_04_audit.sql` | 数据隔离与审计：用户ID绑定、审计日志 |

**重要**：必须按顺序执行，后续脚本依赖前面脚本创建的表。

## 数据库表结构

### 一、用户系统（database_01）

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
| can_transfer | BOOLEAN | 货权转让权限 |
| can_view_finance | BOOLEAN | 财务查看权限 |

**默认账号：** admin/user1/user2，密码均为 `123456`

---

### 二、核心业务表（database_01）

| 表名 | 说明 |
|------|------|
| inventory | 库存主表 - 热卷入库记录 |
| outbound | 出库记录表 - 出库业务记录 |
| outbound_types | 出库类型配置表 |
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

### 三、财务基础表（database_01）

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

### 四、虚拟库存与价格日志（database_01）

| 表名 | 说明 |
|------|------|
| virtual_inventory | 虚拟库存表（邯钢现货）- 与实际库存完全隔离 |
| price_adjustment_logs | 价格调整日志表 |

---

### 五、销售与会计核算（database_02）

| 表名 | 说明 |
|------|------|
| customers | 客户信息表 |
| customer_contacts | 客户联系人表 |
| sales_orders | 销售订单表 |
| sales_order_items | 销售订单明细表 |
| quotations | 报价单表 |
| quotation_items | 报价单明细表 |
| bank_accounts | 银行账户表 |
| accounts_receivable | 应收账款表 |
| receipt_records | 收款记录表 |
| accounts_payable | 应付账款表 |
| payment_records | 付款记录表 |

---

### 六、扩展功能（database_03）

| 表名 | 说明 |
|------|------|
| suppliers | 供应商信息表 |
| cost_records | 成本记录表 |
| product_costs | 产品成本汇总表 |
| invoices | 发票管理表 |
| vat_records | 增值税记录表 |
| surtax_records | 附加税记录表 |
| income_tax_records | 企业所得税记录表 |
| tax_payments | 税款缴纳记录表 |
| accounting_periods | 会计期间表 |
| account_balances | 科目余额表 |
| closing_audit_log | 结账审计日志表 |

---

### 七、数据隔离与审计（database_04）

| 表名 | 说明 |
|------|------|
| vouchers | 凭证表（简化版） |
| tax_summary | 税务汇总表 |
| finance_audit_log | 数据访问审计日志表 |

**database_04 还为以下表添加了 user_id 字段实现数据隔离：**
customers, sales_orders, sales_order_items, quotations, quotation_items, accounts_receivable, receipt_records, accounts_payable, payment_records

---

## 视图

| 视图名 | 来源脚本 | 说明 |
|--------|----------|------|
| current_inventory | database_01 | 当前有效库存视图 |
| outbound_summary | database_01 | 出库统计视图 |
| ar_aging_analysis | database_02 | 应收账款账龄分析视图 |
| sales_statistics | database_02 | 销售统计视图 |

---

## 触发器

| 触发器名 | 说明 |
|----------|------|
| update_users_updated_at | 用户表更新时间自动更新 |
| update_team_notes_updated_at | 团队备注表更新时间自动更新 |
| update_inventory_transfer_updated_at | 货权转让表更新时间自动更新 |
| after_outbound_insert | 出库后自动更新库存状态（货权转让除外） |
| update_customers_updated_at | 客户表更新时间自动更新 |
| update_sales_orders_updated_at | 销售订单表更新时间自动更新 |
| update_virtual_inventory_updated_at | 虚拟库存更新时间自动更新 |

---

## 使用方法

1. 在 Supabase 或 PostgreSQL 中按顺序执行 SQL 脚本
2. 先执行 `database_01_init_complete.sql`，再依次执行 02、03、04
3. 脚本使用 `IF NOT EXISTS` 确保可重复执行
4. 默认用户数据和出库类型会自动插入

## 注意事项

- 所有密码使用 bcrypt 加密存储
- 出库类型4（货权转让）不会改变库存状态
- `database_03_extended.sql` 不再包含 DROP TABLE 操作，可安全执行
- `bank_accounts`、`accounts_payable`、`payment_records` 三张表由 `database_02_sales_accounting.sql` 统一定义，`database_03` 不再重复定义
- `can_view_finance` 字段已包含在 `database_01` 的 users 表定义中，无需单独执行权限补丁脚本

## 已清理的文件

以下文件已整合或移除，备份保存在 `_backup_before_cleanup/` 目录：

| 文件 | 处理方式 | 原因 |
|------|----------|------|
| `database_add_finance_permission.sql` | 已删除 | 功能已合并到 database_01 的 users 表定义中 |
| `database_migration_*.sql` | 已重命名 | 统一编号命名规范 |
| `main_backup_before_enhanced.html` | 已删除 | 旧版备份文件，不再需要 |
| `main_optimized.html` | 已删除 | 旧版优化文件，不再需要 |
| `integrate_javascript.py` | 已删除 | 一次性集成脚本，已完成使命 |
| `replace_filter.ps1` | 已删除 | 一次性替换脚本，已完成使命 |
| `replace_html_template.py` | 已删除 | 一次性替换脚本，已完成使命 |
| `test_window_detection.py` | 已删除 | 测试脚本，非生产代码 |
| `enhanced-filter-integration.js` | 已删除 | 功能已内联到 main.html |
| `enhanced-filter-stats.js` | 已删除 | 功能已内联到 main.html |
