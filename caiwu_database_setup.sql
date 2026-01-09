-- =============================================
-- caiwu财务系统数据库初始化脚本
-- 创建时间: 2025-12-22
-- 目标数据库: Supabase PostgreSQL
-- =============================================

-- 检查现有表结构，避免重复创建
DO $$
BEGIN
    -- 检查是否已存在财务相关表
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounting_subjects') THEN
        -- =============================================
        -- 1. 会计科目表 (accounting_subjects)
        -- =============================================
        CREATE TABLE accounting_subjects (
            subject_id BIGSERIAL PRIMARY KEY,
            subject_code VARCHAR(20) NOT NULL UNIQUE,
            subject_name VARCHAR(100) NOT NULL,
            subject_level SMALLINT DEFAULT 1,
            parent_id BIGINT,
            subject_type SMALLINT NOT NULL,
            balance_direction SMALLINT NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- 为会计科目表创建索引
        CREATE INDEX idx_subjects_code ON accounting_subjects(subject_code);
        CREATE INDEX idx_subjects_parent ON accounting_subjects(parent_id);
        CREATE INDEX idx_subjects_type ON accounting_subjects(subject_type);

        -- 插入基础会计科目数据
        INSERT INTO accounting_subjects (subject_code, subject_name, subject_type, balance_direction) VALUES
            ('1001', '库存现金', 1, 1),
            ('1002', '银行存款', 1, 1),
            ('1122', '应收账款', 1, 1),
            ('1405', '库存商品', 1, 1),
            ('2202', '应付账款', 2, 2),
            ('6001', '主营业务收入', 5, 2),
            ('6401', '主营业务成本', 5, 1),
            ('6601', '销售费用', 5, 1),
            ('6602', '管理费用', 5, 1);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'income_expense_categories') THEN
        -- =============================================
        -- 2. 收支分类表 (income_expense_categories)
        -- =============================================
        CREATE TABLE income_expense_categories (
            category_id BIGSERIAL PRIMARY KEY,
            category_name VARCHAR(100) NOT NULL,
            category_type SMALLINT NOT NULL,
            parent_id BIGINT,
            category_level SMALLINT DEFAULT 1,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- 插入基础收支分类数据
        INSERT INTO income_expense_categories (category_name, category_type) VALUES
            ('销售收入', 1),
            ('其他收入', 1),
            ('采购成本', 2),
            ('运输费用', 2),
            ('人工成本', 2),
            ('办公费用', 2);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reconciliation_records') THEN
        -- =============================================
        -- 3. 对账记录表 (reconciliation_records)
        -- =============================================
        CREATE TABLE reconciliation_records (
            reconciliation_id BIGSERIAL PRIMARY KEY,
            outbound_order_id BIGINT NOT NULL,
            reconciliation_date DATE NOT NULL,
            reconciliation_status SMALLINT DEFAULT 0,
            confirmed_unit_price DECIMAL(10,2),
            confirmed_total_amount DECIMAL(12,2),
            confirmed_by VARCHAR(50),
            confirmed_at TIMESTAMP,
            reconciliation_remark TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            -- 外键约束
            FOREIGN KEY (outbound_order_id) REFERENCES outbound(outbound_order_id) ON DELETE RESTRICT
        );

        -- 为对账记录表创建索引
        CREATE INDEX idx_reconciliation_outbound ON reconciliation_records(outbound_order_id);
        CREATE INDEX idx_reconciliation_date ON reconciliation_records(reconciliation_date);
        CREATE INDEX idx_reconciliation_status ON reconciliation_records(reconciliation_status);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'accounting_vouchers') THEN
        -- =============================================
        -- 4. 会计凭证表 (accounting_vouchers)
        -- =============================================
        CREATE TABLE accounting_vouchers (
            voucher_id BIGSERIAL PRIMARY KEY,
            voucher_no VARCHAR(50) NOT NULL UNIQUE,
            voucher_date DATE NOT NULL,
            voucher_type SMALLINT NOT NULL,
            summary TEXT,
            total_debit DECIMAL(12,2) DEFAULT 0.00,
            total_credit DECIMAL(12,2) DEFAULT 0.00,
            prepared_by VARCHAR(50),
            reviewed_by VARCHAR(50),
            posted BOOLEAN DEFAULT false,
            posted_at TIMESTAMP,
            reconciliation_id BIGINT, -- 关联对账记录
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            -- 外键约束
            FOREIGN KEY (reconciliation_id) REFERENCES reconciliation_records(reconciliation_id) ON DELETE SET NULL
        );

        -- 为会计凭证表创建索引
        CREATE INDEX idx_vouchers_no ON accounting_vouchers(voucher_no);
        CREATE INDEX idx_vouchers_date ON accounting_vouchers(voucher_date);
        CREATE INDEX idx_vouchers_type ON accounting_vouchers(voucher_type);
        CREATE INDEX idx_vouchers_reconciliation ON accounting_vouchers(reconciliation_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'voucher_items') THEN
        -- =============================================
        -- 5. 凭证明细表 (voucher_items)
        -- =============================================
        CREATE TABLE voucher_items (
            item_id BIGSERIAL PRIMARY KEY,
            voucher_id BIGINT NOT NULL,
            subject_id BIGINT NOT NULL,
            debit_amount DECIMAL(12,2) DEFAULT 0.00,
            credit_amount DECIMAL(12,2) DEFAULT 0.00,
            item_summary TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (voucher_id) REFERENCES accounting_vouchers(voucher_id) ON DELETE CASCADE,
            FOREIGN KEY (subject_id) REFERENCES accounting_subjects(subject_id)
        );

        -- 为凭证明细表创建索引
        CREATE INDEX idx_items_voucher ON voucher_items(voucher_id);
        CREATE INDEX idx_items_subject ON voucher_items(subject_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'financial_summary') THEN
        -- =============================================
        -- 6. 财务汇总表 (financial_summary)
        -- =============================================
        CREATE TABLE financial_summary (
            summary_id BIGSERIAL PRIMARY KEY,
            summary_date DATE NOT NULL,
            summary_type SMALLINT NOT NULL,
            total_income DECIMAL(12,2) DEFAULT 0.00,
            total_expense DECIMAL(12,2) DEFAULT 0.00,
            net_profit DECIMAL(12,2) DEFAULT 0.00,
            summary_data JSONB,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        -- 为财务汇总表创建索引
        CREATE INDEX idx_summary_date ON financial_summary(summary_date);
        CREATE INDEX idx_summary_type ON financial_summary(summary_type);
    END IF;

    -- 启用行级安全策略（RLS）
    ALTER TABLE accounting_subjects ENABLE ROW LEVEL SECURITY;
    ALTER TABLE income_expense_categories ENABLE ROW LEVEL SECURITY;
    ALTER TABLE reconciliation_records ENABLE ROW LEVEL SECURITY;
    ALTER TABLE accounting_vouchers ENABLE ROW LEVEL SECURITY;
    ALTER TABLE voucher_items ENABLE ROW LEVEL SECURITY;
    ALTER TABLE financial_summary ENABLE ROW LEVEL SECURITY;

    -- 创建允许匿名访问的策略（根据实际需求调整）
    CREATE POLICY "允许匿名访问会计科目" ON accounting_subjects FOR ALL USING (true);
    CREATE POLICY "允许匿名访问收支分类" ON income_expense_categories FOR ALL USING (true);
    CREATE POLICY "允许匿名访问对账记录" ON reconciliation_records FOR ALL USING (true);
    CREATE POLICY "允许匿名访问会计凭证" ON accounting_vouchers FOR ALL USING (true);
    CREATE POLICY "允许匿名访问凭证明细" ON voucher_items FOR ALL USING (true);
    CREATE POLICY "允许匿名访问财务汇总" ON financial_summary FOR ALL USING (true);

END $$;

-- 输出创建结果
SELECT '数据库表创建完成' as result;
SELECT 
    table_name,
    '创建成功' as status
FROM information_schema.tables 
WHERE table_name IN (
    'accounting_subjects',
    'income_expense_categories', 
    'reconciliation_records',
    'accounting_vouchers',
    'voucher_items',
    'financial_summary'
);