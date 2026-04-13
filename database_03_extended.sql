-- =====================================================
-- 扩展功能数据库迁移脚本（03）
-- 供应商、成本核算、税务管理、期末结账
-- 注意：bank_accounts、accounts_payable、payment_records
-- 已在 database_02_sales_accounting.sql 中定义，此处不再重复
-- 执行顺序：在 database_02_sales_accounting.sql 之后执行
-- =====================================================

-- =====================================================
-- 1. 供应商表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.suppliers (
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

COMMENT ON TABLE public.suppliers IS '供应商信息表';

-- =====================================================
-- 2. 成本记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.cost_records (
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

COMMENT ON TABLE public.cost_records IS '成本记录表';
COMMENT ON COLUMN public.cost_records.cost_type IS '成本类型：material-材料，labor-人工，manufacturing-制造，admin-管理，sales-销售，other-其他';

-- =====================================================
-- 3. 产品成本表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.product_costs (
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

COMMENT ON TABLE public.product_costs IS '产品成本汇总表';

-- =====================================================
-- 4. 发票管理表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.invoices (
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

COMMENT ON TABLE public.invoices IS '发票管理表';
COMMENT ON COLUMN public.invoices.invoice_type IS '发票类型：output-销项，input-进项';

-- =====================================================
-- 5. 增值税记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.vat_records (
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

COMMENT ON TABLE public.vat_records IS '增值税记录表';

-- =====================================================
-- 6. 附加税记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.surtax_records (
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

COMMENT ON TABLE public.surtax_records IS '附加税记录表';

-- =====================================================
-- 7. 企业所得税记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.income_tax_records (
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

COMMENT ON TABLE public.income_tax_records IS '企业所得税记录表';

-- =====================================================
-- 8. 税款缴纳记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.tax_payments (
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

COMMENT ON TABLE public.tax_payments IS '税款缴纳记录表';

-- =====================================================
-- 9. 会计期间表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.accounting_periods (
    period_id SERIAL PRIMARY KEY,
    period VARCHAR(7) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'open',
    checks JSONB,
    closed_at TIMESTAMP,
    reopened_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.accounting_periods IS '会计期间表';
COMMENT ON COLUMN public.accounting_periods.status IS '状态：open-开放，closed-已结账';

-- =====================================================
-- 10. 科目余额表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.account_balances (
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

COMMENT ON TABLE public.account_balances IS '科目余额表';

-- =====================================================
-- 11. 结账审计日志表
-- =====================================================
CREATE TABLE IF NOT EXISTS public.closing_audit_log (
    log_id SERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    action VARCHAR(200) NOT NULL,
    operator VARCHAR(100),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.closing_audit_log IS '结账审计日志表';

-- =====================================================
-- 12. 创建索引
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_cost_records_type ON public.cost_records(cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_date ON public.cost_records(cost_date);
CREATE INDEX IF NOT EXISTS idx_invoices_type ON public.invoices(invoice_type);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON public.invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_vat_records_period ON public.vat_records(period);
CREATE INDEX IF NOT EXISTS idx_tax_payments_period ON public.tax_payments(period);
CREATE INDEX IF NOT EXISTS idx_account_balances_period ON public.account_balances(period);

-- =====================================================
-- 13. 插入示例数据
-- =====================================================

INSERT INTO public.suppliers (supplier_code, supplier_name, contact_person, phone, address, payment_terms, status)
VALUES 
    ('SUP001', '钢材供应商A', '张经理', '13800138001', '上海市浦东新区', 30, 1),
    ('SUP002', '原材料供应商B', '李经理', '13800138002', '江苏省南京市', 45, 1),
    ('SUP003', '设备供应商C', '王经理', '13800138003', '浙江省杭州市', 60, 1)
ON CONFLICT (supplier_code) DO NOTHING;

INSERT INTO public.accounting_periods (period, status)
VALUES (TO_CHAR(CURRENT_DATE, 'YYYY-MM'), 'open')
ON CONFLICT (period) DO NOTHING;

-- =====================================================
-- 完成
-- =====================================================
