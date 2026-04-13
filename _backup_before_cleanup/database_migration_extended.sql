-- =====================================================
-- 扩展功能数据库迁移脚本
-- 应付账款、成本核算、税务管理、期末结账
-- =====================================================

-- =====================================================
-- 添加财务权限字段到用户表（如果不存在）
-- =====================================================
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS can_view_finance BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.users.can_view_finance IS '财务查看权限：true-可查看，false-不可查看';

-- 为管理员用户默认开启财务权限
UPDATE public.users 
SET can_view_finance = true 
WHERE role = 'admin';

-- =====================================================
-- 先删除可能存在的旧表（注意顺序：先删外键引用表）
-- =====================================================
DROP TABLE IF EXISTS closing_audit_log CASCADE;
DROP TABLE IF EXISTS account_balances CASCADE;
DROP TABLE IF EXISTS accounting_periods CASCADE;
DROP TABLE IF EXISTS tax_payments CASCADE;
DROP TABLE IF EXISTS income_tax_records CASCADE;
DROP TABLE IF EXISTS surtax_records CASCADE;
DROP TABLE IF EXISTS vat_records CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS product_costs CASCADE;
DROP TABLE IF EXISTS cost_records CASCADE;
DROP TABLE IF EXISTS payment_records CASCADE;
DROP TABLE IF EXISTS accounts_payable CASCADE;
DROP TABLE IF EXISTS bank_accounts CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

-- =====================================================
-- 1. 供应商表
-- =====================================================
CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_code VARCHAR(50) UNIQUE NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    contact_person VARCHAR(50),
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(500),
    bank_name VARCHAR(100),
    bank_account VARCHAR(50),
    tax_no VARCHAR(50),
    credit_limit DECIMAL(15,2) DEFAULT 0,
    payment_terms INTEGER DEFAULT 30,
    status INTEGER DEFAULT 1,
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE suppliers IS '供应商信息表';

-- =====================================================
-- 2. 银行账户表
-- =====================================================
CREATE TABLE bank_accounts (
    account_id SERIAL PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100),
    bank_account VARCHAR(50) UNIQUE,
    account_type VARCHAR(50),
    currency VARCHAR(10) DEFAULT 'CNY',
    balance DECIMAL(15,2) DEFAULT 0,
    status INTEGER DEFAULT 1,
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE bank_accounts IS '银行账户表';

-- =====================================================
-- 3. 应付账款表
-- =====================================================
CREATE TABLE accounts_payable (
    ap_id SERIAL PRIMARY KEY,
    ap_no VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INTEGER REFERENCES suppliers(supplier_id),
    supplier_name VARCHAR(200),
    invoice_no VARCHAR(50),
    purchase_order_no VARCHAR(50),
    total_amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2) NOT NULL,
    ap_date DATE NOT NULL,
    due_date DATE,
    status INTEGER DEFAULT 1,
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE accounts_payable IS '应付账款表';
COMMENT ON COLUMN accounts_payable.status IS '状态：1-待付款，2-部分付款，3-已付款';

-- =====================================================
-- 4. 付款记录表
-- =====================================================
CREATE TABLE payment_records (
    payment_id SERIAL PRIMARY KEY,
    payable_id INTEGER REFERENCES accounts_payable(ap_id),
    payment_no VARCHAR(50) UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50),
    bank_account_id INTEGER REFERENCES bank_accounts(account_id),
    voucher_no VARCHAR(50),
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE payment_records IS '付款记录表';

-- =====================================================
-- 5. 成本记录表
-- =====================================================
CREATE TABLE cost_records (
    cost_id SERIAL PRIMARY KEY,
    cost_type VARCHAR(50) NOT NULL,
    cost_name VARCHAR(200) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    cost_date DATE NOT NULL,
    product_id INTEGER,
    department VARCHAR(100),
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE cost_records IS '成本记录表';
COMMENT ON COLUMN cost_records.cost_type IS '成本类型：material-材料，labor-人工，manufacturing-制造，admin-管理，sales-销售，other-其他';

-- =====================================================
-- 6. 产品成本表
-- =====================================================
CREATE TABLE product_costs (
    product_cost_id SERIAL PRIMARY KEY,
    product_id INTEGER,
    product_name VARCHAR(200),
    specification VARCHAR(100),
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    quantity DECIMAL(10,2) DEFAULT 0,
    material_cost DECIMAL(15,2) DEFAULT 0,
    labor_cost DECIMAL(15,2) DEFAULT 0,
    manufacturing_cost DECIMAL(15,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    unit_cost DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(year, month, product_id)
);

COMMENT ON TABLE product_costs IS '产品成本汇总表';

-- =====================================================
-- 7. 发票管理表
-- =====================================================
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    invoice_type VARCHAR(20) NOT NULL,
    invoice_no VARCHAR(50) NOT NULL,
    counterparty VARCHAR(200) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    tax_rate DECIMAL(5,4) DEFAULT 0.13,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    invoice_date DATE NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE invoices IS '发票管理表';
COMMENT ON COLUMN invoices.invoice_type IS '发票类型：output-销项，input-进项';

-- =====================================================
-- 8. 增值税记录表
-- =====================================================
CREATE TABLE vat_records (
    vat_id SERIAL PRIMARY KEY,
    period VARCHAR(7) UNIQUE NOT NULL,
    output_tax DECIMAL(15,2) DEFAULT 0,
    input_tax DECIMAL(15,2) DEFAULT 0,
    tax_due DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    payment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE vat_records IS '增值税记录表';

-- =====================================================
-- 9. 附加税记录表
-- =====================================================
CREATE TABLE surtax_records (
    surtax_id SERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    tax_type VARCHAR(50) NOT NULL,
    tax_base DECIMAL(15,2) DEFAULT 0,
    tax_rate DECIMAL(5,4) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(period, tax_type)
);

COMMENT ON TABLE surtax_records IS '附加税记录表';

-- =====================================================
-- 10. 企业所得税记录表
-- =====================================================
CREATE TABLE income_tax_records (
    income_tax_id SERIAL PRIMARY KEY,
    period VARCHAR(7) UNIQUE NOT NULL,
    revenue DECIMAL(15,2) DEFAULT 0,
    cost DECIMAL(15,2) DEFAULT 0,
    profit DECIMAL(15,2) DEFAULT 0,
    tax_rate DECIMAL(5,4) DEFAULT 0.25,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE income_tax_records IS '企业所得税记录表';

-- =====================================================
-- 11. 税款缴纳记录表
-- =====================================================
CREATE TABLE tax_payments (
    tax_payment_id SERIAL PRIMARY KEY,
    payment_no VARCHAR(50) UNIQUE,
    tax_type VARCHAR(50) NOT NULL,
    period VARCHAR(7) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50),
    remark TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE tax_payments IS '税款缴纳记录表';

-- =====================================================
-- 12. 会计期间表
-- =====================================================
CREATE TABLE accounting_periods (
    period_id SERIAL PRIMARY KEY,
    period VARCHAR(7) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'open',
    checks JSONB,
    closed_at TIMESTAMP,
    reopened_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE accounting_periods IS '会计期间表';
COMMENT ON COLUMN accounting_periods.status IS '状态：open-开放，closed-已结账';

-- =====================================================
-- 13. 科目余额表
-- =====================================================
CREATE TABLE account_balances (
    balance_id SERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    account_code VARCHAR(50) NOT NULL,
    account_name VARCHAR(200),
    opening_balance DECIMAL(15,2) DEFAULT 0,
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    closing_balance DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(period, account_code)
);

COMMENT ON TABLE account_balances IS '科目余额表';

-- =====================================================
-- 14. 结账审计日志表
-- =====================================================
CREATE TABLE closing_audit_log (
    log_id SERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    action VARCHAR(200) NOT NULL,
    operator VARCHAR(100),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE closing_audit_log IS '结账审计日志表';

-- =====================================================
-- 15. 创建索引
-- =====================================================
CREATE INDEX idx_accounts_payable_supplier ON accounts_payable(supplier_id);
CREATE INDEX idx_accounts_payable_status ON accounts_payable(status);
CREATE INDEX idx_accounts_payable_date ON accounts_payable(ap_date);
CREATE INDEX idx_payment_records_payable ON payment_records(payable_id);
CREATE INDEX idx_cost_records_type ON cost_records(cost_type);
CREATE INDEX idx_cost_records_date ON cost_records(cost_date);
CREATE INDEX idx_invoices_type ON invoices(invoice_type);
CREATE INDEX idx_invoices_date ON invoices(invoice_date);
CREATE INDEX idx_vat_records_period ON vat_records(period);
CREATE INDEX idx_tax_payments_period ON tax_payments(period);
CREATE INDEX idx_account_balances_period ON account_balances(period);

-- =====================================================
-- 16. 插入示例数据
-- =====================================================

-- 插入示例供应商
INSERT INTO suppliers (supplier_code, supplier_name, contact_person, phone, address, payment_terms, status)
VALUES 
    ('SUP001', '钢材供应商A', '张经理', '13800138001', '上海市浦东新区', 30, 1),
    ('SUP002', '原材料供应商B', '李经理', '13800138002', '江苏省南京市', 45, 1),
    ('SUP003', '设备供应商C', '王经理', '13800138003', '浙江省杭州市', 60, 1);

-- 插入示例银行账户
INSERT INTO bank_accounts (account_name, bank_name, bank_account, account_type, balance, status)
VALUES 
    ('基本户', '中国工商银行', '1234567890123456789', 'basic', 1000000, 1),
    ('一般户', '中国建设银行', '9876543210987654321', 'general', 500000, 1);

-- 插入当前会计期间
INSERT INTO accounting_periods (period, status)
VALUES (TO_CHAR(CURRENT_DATE, 'YYYY-MM'), 'open');

-- =====================================================
-- 完成
-- =====================================================
