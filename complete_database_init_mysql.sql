-- =============================================
-- 热卷打印管理系统 - 完整数据库初始化脚本 (MySQL版本)
-- 创建时间: 2026-01-23
-- 目标数据库: MySQL 5.7+
-- 说明: 此脚本包含系统所有需要的数据库表
-- =============================================

-- 设置字符集和排序规则
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================
-- 1. 库存表 (inventory) - 主表
-- =============================================
CREATE TABLE IF NOT EXISTS `inventory` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键标识',
    
    -- 核心业务字段
    `batch_no` VARCHAR(50) NOT NULL COMMENT '批号，唯一标识符',
    `unit` VARCHAR(20) NOT NULL COMMENT '单位（如：吨、公斤、件）',
    `specification` VARCHAR(100) NOT NULL COMMENT '规格描述',
    `material` VARCHAR(50) NOT NULL COMMENT '材料类型',
    
    -- 重量信息
    `weight` DECIMAL(15,3) NOT NULL COMMENT '入库重量',
    
    -- 物流信息
    `vehicle_no` VARCHAR(20) DEFAULT NULL COMMENT '入库车牌号',
    `transport_fee` DECIMAL(10,2) DEFAULT 0.00 COMMENT '运输费用',
    `advance_payment` DECIMAL(10,2) DEFAULT 0.00 COMMENT '预付款',
    
    -- 存储信息
    `storage_location` VARCHAR(100) NOT NULL COMMENT '存储位置',
    `in_date` DATE NOT NULL COMMENT '入库日期',
    
    -- 状态管理
    `status` SMALLINT DEFAULT 1 COMMENT '状态：1-在库 2-已出库 3-冻结',
    
    -- 备注信息
    `remark` TEXT DEFAULT NULL COMMENT '备注信息',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_batch_no` (`batch_no`),
    KEY `idx_material` (`material`),
    KEY `idx_specification` (`specification`),
    KEY `idx_in_date` (`in_date`),
    KEY `idx_status` (`status`),
    KEY `idx_storage_location` (`storage_location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='库存主表';

-- =============================================
-- 2. 出库表 (outbound) - 关联表
-- =============================================
CREATE TABLE IF NOT EXISTS `outbound` (
    `outbound_order_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '出库记录唯一标识',
    
    -- 关联字段
    `inventory_id` BIGINT NOT NULL COMMENT '关联库存记录ID',
    `batch_no` VARCHAR(50) NOT NULL COMMENT '批号，冗余存储便于查询',
    
    -- 产品信息（冗余存储，避免频繁联表查询）
    `material` VARCHAR(50) NOT NULL COMMENT '材料类型',
    `specification` VARCHAR(100) NOT NULL COMMENT '规格描述',
    
    -- 重量信息
    `stock_weight` DECIMAL(15,3) NOT NULL COMMENT '出库前库存重量',
    `out_weight` DECIMAL(15,3) NOT NULL COMMENT '出库重量',
    
    -- 财务信息
    `unit_price` DECIMAL(10,2) NOT NULL COMMENT '单价',
    `total_amount` DECIMAL(12,2) NOT NULL COMMENT '总金额',
    
    -- 出库业务信息
    `out_type` SMALLINT DEFAULT 1 COMMENT '出库类型：1-销售出库 2-调拨出库 3-退货出库',
    `out_date` DATE NOT NULL COMMENT '出库日期',
    
    -- 物流信息
    `vehicle_no` VARCHAR(20) DEFAULT NULL COMMENT '出库车牌号',
    
    -- 出库单号
    `ref_no` VARCHAR(50) DEFAULT NULL COMMENT '出库单号，格式：OUTYYYYMMDDXXX',
    
    -- 备注信息
    `remark` TEXT DEFAULT NULL COMMENT '出库备注',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    PRIMARY KEY (`outbound_order_id`),
    KEY `idx_inventory_id` (`inventory_id`),
    KEY `idx_batch_no` (`batch_no`),
    KEY `idx_out_date` (`out_date`),
    KEY `idx_out_type` (`out_type`),
    KEY `idx_material` (`material`),
    KEY `idx_ref_no` (`ref_no`),
    CONSTRAINT `fk_outbound_inventory` FOREIGN KEY (`inventory_id`) 
        REFERENCES `inventory` (`id`) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='出库记录表';

-- =============================================
-- 3. 财务台账表 (finance_ledger)
-- =============================================
CREATE TABLE IF NOT EXISTS `finance_ledger` (
    `ledger_id` INT NOT NULL AUTO_INCREMENT COMMENT '台账记录唯一标识',
    
    -- 关联字段
    `outbound_order_id` BIGINT DEFAULT NULL COMMENT '关联出库记录ID',
    
    -- 财务信息
    `ref_no` VARCHAR(50) NOT NULL COMMENT '关联单号',
    `transaction_date` DATE NOT NULL COMMENT '交易日期',
    `transaction_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '交易时间',
    `transaction_type` VARCHAR(20) NOT NULL COMMENT '交易类型：income-收入 expense-支出',
    `transaction_category` VARCHAR(50) DEFAULT NULL COMMENT '交易分类',
    `description` TEXT DEFAULT NULL COMMENT '描述',
    `unit` VARCHAR(10) DEFAULT '元' COMMENT '单位',
    `amount` DECIMAL(15,2) NOT NULL COMMENT '金额',
    `tax_amount` DECIMAL(15,2) DEFAULT 0 COMMENT '税额',
    `total_amount` DECIMAL(15,2) NOT NULL COMMENT '总金额',
    
    -- 客户供应商信息
    `customer_supplier` VARCHAR(100) DEFAULT NULL COMMENT '客户/供应商',
    `batch_no` VARCHAR(50) DEFAULT NULL COMMENT '批号',
    `quantity` DECIMAL(10,3) DEFAULT NULL COMMENT '数量',
    `unit_price` DECIMAL(10,2) DEFAULT NULL COMMENT '单价',
    
    -- 会计科目
    `debit_account` VARCHAR(50) DEFAULT NULL COMMENT '借方科目',
    `credit_account` VARCHAR(50) DEFAULT NULL COMMENT '贷方科目',
    
    -- 支付信息
    `payment_method` VARCHAR(20) DEFAULT NULL COMMENT '支付方式',
    `bank_account` VARCHAR(50) DEFAULT NULL COMMENT '银行账户',
    
    -- 状态信息
    `status` VARCHAR(20) DEFAULT 'pending' COMMENT '状态：pending-待处理 completed-已完成',
    `is_reconciled` BOOLEAN DEFAULT FALSE COMMENT '是否已对账',
    `created_by` VARCHAR(50) DEFAULT NULL COMMENT '创建人',
    `approved_by` VARCHAR(50) DEFAULT NULL COMMENT '审核人',
    `approved_at` TIMESTAMP DEFAULT NULL COMMENT '审核时间',
    
    -- 同步信息
    `modification_reason` TEXT DEFAULT NULL COMMENT '修改原因',
    `sync_source` VARCHAR(50) DEFAULT 'manual' COMMENT '同步来源',
    `sync_status` VARCHAR(20) DEFAULT 'pending' COMMENT '同步状态',
    `sync_attempts` INT DEFAULT 0 COMMENT '同步尝试次数',
    `last_sync_time` TIMESTAMP DEFAULT NULL COMMENT '最后同步时间',
    `is_deleted` BOOLEAN DEFAULT FALSE COMMENT '是否删除',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`ledger_id`),
    UNIQUE KEY `uk_ref_no` (`ref_no`),
    KEY `idx_outbound_order_id` (`outbound_order_id`),
    KEY `idx_transaction_date` (`transaction_date`),
    KEY `idx_transaction_type` (`transaction_type`),
    KEY `idx_sync_source` (`sync_source`),
    CONSTRAINT `fk_finance_ledger_outbound` FOREIGN KEY (`outbound_order_id`) 
        REFERENCES `outbound` (`outbound_order_id`) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='财务台账表';

-- =============================================
-- 4. 日常记账表 (daily_accounting)
-- =============================================
CREATE TABLE IF NOT EXISTS `daily_accounting` (
    `daily_id` INT NOT NULL AUTO_INCREMENT COMMENT '记账记录唯一标识',
    
    -- 财务信息
    `accounting_date` DATE NOT NULL COMMENT '记账日期',
    `summary` VARCHAR(200) DEFAULT NULL COMMENT '摘要',
    `description` TEXT DEFAULT NULL COMMENT '描述',
    `total_income` DECIMAL(15,2) DEFAULT 0 COMMENT '总收入',
    `total_expense` DECIMAL(15,2) DEFAULT 0 COMMENT '总支出',
    `total_transactions` INT DEFAULT 0 COMMENT '交易笔数',
    
    -- 状态信息
    `is_closed` BOOLEAN DEFAULT FALSE COMMENT '是否已结账',
    `closed_by` VARCHAR(50) DEFAULT NULL COMMENT '结账人',
    `closed_at` TIMESTAMP DEFAULT NULL COMMENT '结账时间',
    `reviewed_by` VARCHAR(50) DEFAULT NULL COMMENT '审核人',
    `reviewed_at` TIMESTAMP DEFAULT NULL COMMENT '审核时间',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`daily_id`),
    UNIQUE KEY `uk_accounting_date` (`accounting_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='日常记账表';

-- =============================================
-- 5. 团队备注表 (team_notes)
-- =============================================
CREATE TABLE IF NOT EXISTS `team_notes` (
    `id` VARCHAR(50) NOT NULL COMMENT 'ID',
    
    -- 团队信息
    `a_team` TEXT DEFAULT '' COMMENT 'A团队',
    `b_team` TEXT DEFAULT '' COMMENT 'B团队',
    `c_team` TEXT DEFAULT '' COMMENT 'C团队',
    
    -- JSON数据
    `outbound_orders` JSON DEFAULT NULL COMMENT '出库订单JSON',
    `outbound_batches` JSON DEFAULT NULL COMMENT '出库批次JSON',
    `coil_inventory` JSON DEFAULT NULL COMMENT '库存JSON',
    
    -- 系统字段
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='团队备注表';

-- =============================================
-- 6. 对账记录表 (reconciliation_records)
-- =============================================
CREATE TABLE IF NOT EXISTS `reconciliation_records` (
    `reconciliation_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '对账记录唯一标识',
    
    -- 关联字段
    `outbound_order_id` BIGINT NOT NULL COMMENT '关联出库记录ID',
    
    -- 对账信息
    `reconciliation_date` DATE NOT NULL COMMENT '对账日期',
    `reconciliation_status` SMALLINT DEFAULT 0 COMMENT '对账状态：0-未对账 1-已对账',
    `confirmed_unit_price` DECIMAL(10,2) DEFAULT NULL COMMENT '确认单价',
    `confirmed_total_amount` DECIMAL(12,2) DEFAULT NULL COMMENT '确认总金额',
    `confirmed_by` VARCHAR(50) DEFAULT NULL COMMENT '确认人',
    `confirmed_at` TIMESTAMP DEFAULT NULL COMMENT '确认时间',
    `reconciliation_remark` TEXT DEFAULT NULL COMMENT '对账备注',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`reconciliation_id`),
    KEY `idx_outbound_order_id` (`outbound_order_id`),
    KEY `idx_reconciliation_date` (`reconciliation_date`),
    KEY `idx_reconciliation_status` (`reconciliation_status`),
    CONSTRAINT `fk_reconciliation_outbound` FOREIGN KEY (`outbound_order_id`) 
        REFERENCES `outbound` (`outbound_order_id`) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='对账记录表';

-- =============================================
-- 7. 会计科目表 (accounting_subjects)
-- =============================================
CREATE TABLE IF NOT EXISTS `accounting_subjects` (
    `subject_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '科目ID',
    
    -- 科目信息
    `subject_code` VARCHAR(20) NOT NULL COMMENT '科目编码',
    `subject_name` VARCHAR(100) NOT NULL COMMENT '科目名称',
    `subject_level` SMALLINT DEFAULT 1 COMMENT '科目级别',
    `parent_id` BIGINT DEFAULT NULL COMMENT '父科目ID',
    `subject_type` SMALLINT NOT NULL COMMENT '科目类型：1-资产 2-负债 3-所有者权益 4-成本 5-损益',
    `balance_direction` SMALLINT NOT NULL COMMENT '余额方向：1-借方 2-贷方',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`subject_id`),
    UNIQUE KEY `uk_subject_code` (`subject_code`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_subject_type` (`subject_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会计科目表';

-- 插入基础会计科目数据
INSERT INTO `accounting_subjects` (`subject_code`, `subject_name`, `subject_type`, `balance_direction`) VALUES
    ('1001', '库存现金', 1, 1),
    ('1002', '银行存款', 1, 1),
    ('1122', '应收账款', 1, 1),
    ('1405', '库存商品', 1, 1),
    ('2202', '应付账款', 2, 2),
    ('6001', '主营业务收入', 5, 2),
    ('6401', '主营业务成本', 5, 1),
    ('6601', '销售费用', 5, 1),
    ('6602', '管理费用', 5, 1)
ON DUPLICATE KEY UPDATE `subject_name` = VALUES(`subject_name`);

-- =============================================
-- 8. 收支分类表 (income_expense_categories)
-- =============================================
CREATE TABLE IF NOT EXISTS `income_expense_categories` (
    `category_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '分类ID',
    
    -- 分类信息
    `category_name` VARCHAR(100) NOT NULL COMMENT '分类名称',
    `category_type` SMALLINT NOT NULL COMMENT '分类类型：1-收入 2-支出',
    `parent_id` BIGINT DEFAULT NULL COMMENT '父分类ID',
    `category_level` SMALLINT DEFAULT 1 COMMENT '分类级别',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT '是否启用',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    PRIMARY KEY (`category_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收支分类表';

-- 插入基础收支分类数据
INSERT INTO `income_expense_categories` (`category_name`, `category_type`) VALUES
    ('销售收入', 1),
    ('其他收入', 1),
    ('采购成本', 2),
    ('运输费用', 2),
    ('人工成本', 2),
    ('办公费用', 2)
ON DUPLICATE KEY UPDATE `category_name` = VALUES(`category_name`);

-- =============================================
-- 9. 会计凭证表 (accounting_vouchers)
-- =============================================
CREATE TABLE IF NOT EXISTS `accounting_vouchers` (
    `voucher_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '凭证ID',
    
    -- 凭证信息
    `voucher_no` VARCHAR(50) NOT NULL COMMENT '凭证号',
    `voucher_date` DATE NOT NULL COMMENT '凭证日期',
    `voucher_type` SMALLINT NOT NULL COMMENT '凭证类型',
    `summary` TEXT DEFAULT NULL COMMENT '摘要',
    `total_debit` DECIMAL(12,2) DEFAULT 0.00 COMMENT '借方合计',
    `total_credit` DECIMAL(12,2) DEFAULT 0.00 COMMENT '贷方合计',
    
    -- 审核信息
    `prepared_by` VARCHAR(50) DEFAULT NULL COMMENT '制单人',
    `reviewed_by` VARCHAR(50) DEFAULT NULL COMMENT '审核人',
    `posted` BOOLEAN DEFAULT FALSE COMMENT '是否已过账',
    `posted_at` TIMESTAMP DEFAULT NULL COMMENT '过账时间',
    
    -- 关联字段
    `reconciliation_id` BIGINT DEFAULT NULL COMMENT '关联对账记录ID',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    PRIMARY KEY (`voucher_id`),
    UNIQUE KEY `uk_voucher_no` (`voucher_no`),
    KEY `idx_voucher_date` (`voucher_date`),
    KEY `idx_voucher_type` (`voucher_type`),
    KEY `idx_reconciliation_id` (`reconciliation_id`),
    CONSTRAINT `fk_voucher_reconciliation` FOREIGN KEY (`reconciliation_id`) 
        REFERENCES `reconciliation_records` (`reconciliation_id`) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='会计凭证表';

-- =============================================
-- 10. 凭证明细表 (voucher_items)
-- =============================================
CREATE TABLE IF NOT EXISTS `voucher_items` (
    `item_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '明细ID',
    
    -- 关联字段
    `voucher_id` BIGINT NOT NULL COMMENT '凭证ID',
    `subject_id` BIGINT NOT NULL COMMENT '科目ID',
    
    -- 金额信息
    `debit_amount` DECIMAL(12,2) DEFAULT 0.00 COMMENT '借方金额',
    `credit_amount` DECIMAL(12,2) DEFAULT 0.00 COMMENT '贷方金额',
    `item_summary` TEXT DEFAULT NULL COMMENT '摘要',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    PRIMARY KEY (`item_id`),
    KEY `idx_voucher_id` (`voucher_id`),
    KEY `idx_subject_id` (`subject_id`),
    CONSTRAINT `fk_item_voucher` FOREIGN KEY (`voucher_id`) 
        REFERENCES `accounting_vouchers` (`voucher_id`) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT `fk_item_subject` FOREIGN KEY (`subject_id`) 
        REFERENCES `accounting_subjects` (`subject_id`) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='凭证明细表';

-- =============================================
-- 11. 财务汇总表 (financial_summary)
-- =============================================
CREATE TABLE IF NOT EXISTS `financial_summary` (
    `summary_id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '汇总ID',
    
    -- 汇总信息
    `summary_date` DATE NOT NULL COMMENT '汇总日期',
    `summary_type` SMALLINT NOT NULL COMMENT '汇总类型',
    `total_income` DECIMAL(12,2) DEFAULT 0.00 COMMENT '总收入',
    `total_expense` DECIMAL(12,2) DEFAULT 0.00 COMMENT '总支出',
    `net_profit` DECIMAL(12,2) DEFAULT 0.00 COMMENT '净利润',
    `summary_data` JSON DEFAULT NULL COMMENT '汇总数据（JSON格式）',
    
    -- 系统字段
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    PRIMARY KEY (`summary_id`),
    KEY `idx_summary_date` (`summary_date`),
    KEY `idx_summary_type` (`summary_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='财务汇总表';

-- =============================================
-- 12. 视图 - 库存状态统计
-- 注意：如果数据库用户没有CREATE VIEW权限，请注释掉以下部分
-- =============================================

-- 当前有效库存视图
-- CREATE OR REPLACE VIEW `current_inventory` AS
-- SELECT 
--     `i`.`id`,
--     `i`.`batch_no`,
--     `i`.`unit`,
--     `i`.`specification`,
--     `i`.`material`,
--     `i`.`weight`,
--     `i`.`storage_location`,
--     `i`.`in_date`,
--     `i`.`status`,
--     `i`.`created_at`
-- FROM `inventory` `i`
-- WHERE `i`.`status` = 1
-- ORDER BY `i`.`in_date` DESC, `i`.`batch_no`;

-- 出库统计视图
-- CREATE OR REPLACE VIEW `outbound_summary` AS
-- SELECT 
--     `o`.`outbound_order_id`,
--     `o`.`batch_no`,
--     `o`.`material`,
--     `o`.`specification`,
--     `o`.`out_weight`,
--     `o`.`unit_price`,
--     `o`.`total_amount`,
--     `o`.`out_date`,
--     `o`.`out_type`,
--     `i`.`storage_location` AS `original_storage`
-- FROM `outbound` `o`
-- JOIN `inventory` `i` ON `o`.`inventory_id` = `i`.`id`
-- ORDER BY `o`.`out_date` DESC;

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- 13. 输出创建结果
-- =============================================
SELECT '数据库表创建完成' AS result;
SELECT '请手动验证以下表是否创建成功' AS message;
