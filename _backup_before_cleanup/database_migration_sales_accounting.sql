-- =============================================
-- 销售管理与会计核算系统 - 数据库迁移脚本
-- 创建时间: 2026-04-06
-- 目标数据库: PostgreSQL / Supabase
-- =============================================

-- =============================================
-- 第一部分：销售管理表
-- =============================================

-- 客户表
CREATE TABLE IF NOT EXISTS public.customers (
    customer_id BIGSERIAL PRIMARY KEY,
    customer_code VARCHAR(20) UNIQUE NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    customer_type SMALLINT DEFAULT 1,
    credit_code VARCHAR(50),
    contact_person VARCHAR(50),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    province VARCHAR(50),
    city VARCHAR(50),
    address TEXT,
    credit_limit DECIMAL(12,2) DEFAULT 0,
    current_arrears DECIMAL(12,2) DEFAULT 0,
    payment_terms VARCHAR(50),
    remark TEXT,
    status SMALLINT DEFAULT 1,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_name ON public.customers(customer_name);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_type ON public.customers(customer_type);

COMMENT ON TABLE public.customers IS '客户信息表';
COMMENT ON COLUMN public.customers.customer_id IS '客户ID';
COMMENT ON COLUMN public.customers.customer_code IS '客户编码';
COMMENT ON COLUMN public.customers.customer_name IS '客户名称';
COMMENT ON COLUMN public.customers.customer_type IS '客户类型：1-企业，2-个人';
COMMENT ON COLUMN public.customers.credit_code IS '统一社会信用代码';
COMMENT ON COLUMN public.customers.contact_person IS '联系人';
COMMENT ON COLUMN public.customers.contact_phone IS '联系电话';
COMMENT ON COLUMN public.customers.contact_email IS '联系邮箱';
COMMENT ON COLUMN public.customers.province IS '省份';
COMMENT ON COLUMN public.customers.city IS '城市';
COMMENT ON COLUMN public.customers.address IS '详细地址';
COMMENT ON COLUMN public.customers.credit_limit IS '信用额度';
COMMENT ON COLUMN public.customers.current_arrears IS '当前欠款';
COMMENT ON COLUMN public.customers.payment_terms IS '付款条件';
COMMENT ON COLUMN public.customers.remark IS '备注';
COMMENT ON COLUMN public.customers.status IS '状态：1-正常，0-禁用';
COMMENT ON COLUMN public.customers.created_by IS '创建人';

-- 客户联系人表
CREATE TABLE IF NOT EXISTS public.customer_contacts (
    contact_id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    contact_name VARCHAR(50) NOT NULL,
    contact_position VARCHAR(50),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(100),
    is_primary BOOLEAN DEFAULT FALSE,
    remark TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customer_contacts_customer ON public.customer_contacts(customer_id);

COMMENT ON TABLE public.customer_contacts IS '客户联系人表';

-- 销售订单表
CREATE TABLE IF NOT EXISTS public.sales_orders (
    order_id BIGSERIAL PRIMARY KEY,
    order_no VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT REFERENCES customers(customer_id),
    customer_name VARCHAR(100),
    order_date DATE NOT NULL,
    delivery_date DATE,
    total_quantity DECIMAL(10,3) DEFAULT 0,
    total_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    final_amount DECIMAL(12,2) DEFAULT 0,
    order_status SMALLINT DEFAULT 1,
    payment_status SMALLINT DEFAULT 1,
    payment_method VARCHAR(20),
    salesperson VARCHAR(50),
    salesperson_id BIGINT,
    remark TEXT,
    internal_remark TEXT,
    created_by VARCHAR(50),
    approved_by VARCHAR(50),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_orders_no ON public.sales_orders(order_no);
CREATE INDEX IF NOT EXISTS idx_sales_orders_customer ON public.sales_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_date ON public.sales_orders(order_date);
CREATE INDEX IF NOT EXISTS idx_sales_orders_status ON public.sales_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_sales_orders_payment ON public.sales_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_sales_orders_salesperson ON public.sales_orders(salesperson);

COMMENT ON TABLE public.sales_orders IS '销售订单表';
COMMENT ON COLUMN public.sales_orders.order_no IS '订单编号';
COMMENT ON COLUMN public.sales_orders.order_status IS '订单状态：1-待审核，2-已审核，3-已完成，4-已取消';
COMMENT ON COLUMN public.sales_orders.payment_status IS '付款状态：1-未付款，2-部分付款，3-已付款';

-- 销售订单明细表
CREATE TABLE IF NOT EXISTS public.sales_order_items (
    item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES sales_orders(order_id) ON DELETE CASCADE,
    inventory_id BIGINT REFERENCES inventory(id),
    batch_no VARCHAR(50),
    product_name VARCHAR(100),
    specification VARCHAR(100),
    material VARCHAR(50),
    quantity DECIMAL(10,3) NOT NULL,
    unit VARCHAR(20),
    unit_price DECIMAL(10,2) NOT NULL,
    amount DECIMAL(12,2),
    tax_rate DECIMAL(5,2) DEFAULT 13.00,
    tax_amount DECIMAL(12,2),
    discount_rate DECIMAL(5,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    final_amount DECIMAL(12,2),
    delivery_date DATE,
    remark TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_order_items_order ON public.sales_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_inventory ON public.sales_order_items(inventory_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_batch ON public.sales_order_items(batch_no);

COMMENT ON TABLE public.sales_order_items IS '销售订单明细表';

-- 报价单表
CREATE TABLE IF NOT EXISTS public.quotations (
    quotation_id BIGSERIAL PRIMARY KEY,
    quotation_no VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT REFERENCES customers(customer_id),
    customer_name VARCHAR(100),
    quotation_date DATE NOT NULL,
    valid_until DATE,
    total_amount DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    status SMALLINT DEFAULT 1,
    salesperson VARCHAR(50),
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotations_no ON public.quotations(quotation_no);
CREATE INDEX IF NOT EXISTS idx_quotations_customer ON public.quotations(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotations_date ON public.quotations(quotation_date);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON public.quotations(status);

COMMENT ON TABLE public.quotations IS '报价单表';
COMMENT ON COLUMN public.quotations.status IS '状态：1-有效，2-已过期，3-已转订单';

-- 报价单明细表
CREATE TABLE IF NOT EXISTS public.quotation_items (
    item_id BIGSERIAL PRIMARY KEY,
    quotation_id BIGINT NOT NULL REFERENCES quotations(quotation_id) ON DELETE CASCADE,
    product_name VARCHAR(100),
    specification VARCHAR(100),
    material VARCHAR(50),
    quantity DECIMAL(10,3),
    unit VARCHAR(20),
    unit_price DECIMAL(10,2),
    amount DECIMAL(12,2),
    tax_rate DECIMAL(5,2) DEFAULT 13.00,
    tax_amount DECIMAL(12,2),
    remark TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotation_items_quotation ON public.quotation_items(quotation_id);

-- =============================================
-- 第二部分：会计核算表
-- =============================================

-- 银行账户表
CREATE TABLE IF NOT EXISTS public.bank_accounts (
    account_id BIGSERIAL PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100),
    bank_account VARCHAR(50),
    account_type SMALLINT DEFAULT 2,
    currency VARCHAR(10) DEFAULT 'CNY',
    opening_balance DECIMAL(15,2) DEFAULT 0,
    current_balance DECIMAL(15,2) DEFAULT 0,
    status SMALLINT DEFAULT 1,
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bank_accounts_code ON public.bank_accounts(account_code);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_type ON public.bank_accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_status ON public.bank_accounts(status);

COMMENT ON TABLE public.bank_accounts IS '银行账户表';
COMMENT ON COLUMN public.bank_accounts.account_type IS '账户类型：1-现金，2-银行存款，3-支付宝，4-微信，5-其他';
COMMENT ON COLUMN public.bank_accounts.status IS '状态：1-正常，0-禁用';

-- 应收账款表
CREATE TABLE IF NOT EXISTS public.accounts_receivable (
    ar_id BIGSERIAL PRIMARY KEY,
    ar_no VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT REFERENCES customers(customer_id),
    customer_name VARCHAR(100),
    order_id BIGINT REFERENCES sales_orders(order_id),
    order_no VARCHAR(50),
    outbound_id BIGINT REFERENCES outbound(outbound_order_id),
    ar_date DATE NOT NULL,
    due_date DATE,
    original_amount DECIMAL(12,2) NOT NULL,
    received_amount DECIMAL(12,2) DEFAULT 0,
    remaining_amount DECIMAL(12,2),
    invoice_status SMALLINT DEFAULT 0,
    invoice_no VARCHAR(50),
    invoice_date DATE,
    invoice_amount DECIMAL(12,2),
    status SMALLINT DEFAULT 1,
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ar_no ON public.accounts_receivable(ar_no);
CREATE INDEX IF NOT EXISTS idx_ar_customer ON public.accounts_receivable(customer_id);
CREATE INDEX IF NOT EXISTS idx_ar_order ON public.accounts_receivable(order_id);
CREATE INDEX IF NOT EXISTS idx_ar_date ON public.accounts_receivable(ar_date);
CREATE INDEX IF NOT EXISTS idx_ar_due_date ON public.accounts_receivable(due_date);
CREATE INDEX IF NOT EXISTS idx_ar_status ON public.accounts_receivable(status);

COMMENT ON TABLE public.accounts_receivable IS '应收账款表';
COMMENT ON COLUMN public.accounts_receivable.invoice_status IS '开票状态：0-未开票，1-已开票';
COMMENT ON COLUMN public.accounts_receivable.status IS '状态：1-未收款，2-部分收款，3-已结清';

-- 收款记录表
CREATE TABLE IF NOT EXISTS public.receipt_records (
    receipt_id BIGSERIAL PRIMARY KEY,
    receipt_no VARCHAR(50) UNIQUE NOT NULL,
    ar_id BIGINT REFERENCES accounts_receivable(ar_id),
    customer_id BIGINT REFERENCES customers(customer_id),
    customer_name VARCHAR(100),
    receipt_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20),
    bank_account_id BIGINT REFERENCES bank_accounts(account_id),
    voucher_no VARCHAR(50),
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_receipt_no ON public.receipt_records(receipt_no);
CREATE INDEX IF NOT EXISTS idx_receipt_ar ON public.receipt_records(ar_id);
CREATE INDEX IF NOT EXISTS idx_receipt_customer ON public.receipt_records(customer_id);
CREATE INDEX IF NOT EXISTS idx_receipt_date ON public.receipt_records(receipt_date);

COMMENT ON TABLE public.receipt_records IS '收款记录表';
COMMENT ON COLUMN public.receipt_records.payment_method IS '付款方式：cash-现金，bank_transfer-银行转账，alipay-支付宝，wechat-微信';

-- 应付账款表
CREATE TABLE IF NOT EXISTS public.accounts_payable (
    ap_id BIGSERIAL PRIMARY KEY,
    ap_no VARCHAR(50) UNIQUE NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_id BIGINT,
    inventory_id BIGINT REFERENCES inventory(id),
    batch_no VARCHAR(50),
    ap_date DATE NOT NULL,
    due_date DATE,
    original_amount DECIMAL(12,2) NOT NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    remaining_amount DECIMAL(12,2),
    invoice_status SMALLINT DEFAULT 0,
    invoice_no VARCHAR(50),
    invoice_date DATE,
    invoice_amount DECIMAL(12,2),
    status SMALLINT DEFAULT 1,
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ap_no ON public.accounts_payable(ap_no);
CREATE INDEX IF NOT EXISTS idx_ap_supplier ON public.accounts_payable(supplier_name);
CREATE INDEX IF NOT EXISTS idx_ap_date ON public.accounts_payable(ap_date);
CREATE INDEX IF NOT EXISTS idx_ap_status ON public.accounts_payable(status);

COMMENT ON TABLE public.accounts_payable IS '应付账款表';
COMMENT ON COLUMN public.accounts_payable.status IS '状态：1-未付款，2-部分付款，3-已结清';

-- 付款记录表
CREATE TABLE IF NOT EXISTS public.payment_records (
    payment_id BIGSERIAL PRIMARY KEY,
    payment_no VARCHAR(50) UNIQUE NOT NULL,
    ap_id BIGINT REFERENCES accounts_payable(ap_id),
    supplier_name VARCHAR(100),
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(20),
    bank_account_id BIGINT REFERENCES bank_accounts(account_id),
    voucher_no VARCHAR(50),
    remark TEXT,
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_no ON public.payment_records(payment_no);
CREATE INDEX IF NOT EXISTS idx_payment_ap ON public.payment_records(ap_id);
CREATE INDEX IF NOT EXISTS idx_payment_date ON public.payment_records(payment_date);

COMMENT ON TABLE public.payment_records IS '付款记录表';

-- =============================================
-- 第三部分：扩展会计科目表
-- =============================================

-- 扩展会计科目数据
INSERT INTO public.accounting_subjects (subject_code, subject_name, subject_type, balance_direction, subject_level)
VALUES
    ('1001', '库存现金', 1, 1, 1),
    ('1002', '银行存款', 1, 1, 1),
    ('1012', '其他货币资金', 1, 1, 1),
    ('1121', '应收票据', 1, 1, 1),
    ('1122', '应收账款', 1, 1, 1),
    ('1123', '预付账款', 1, 1, 1),
    ('1221', '其他应收款', 1, 1, 1),
    ('1401', '材料采购', 1, 1, 1),
    ('1405', '原材料', 1, 1, 1),
    ('1406', '库存商品', 1, 1, 1),
    ('2201', '应付票据', 2, 2, 1),
    ('2202', '应付账款', 2, 2, 1),
    ('2203', '预收账款', 2, 2, 1),
    ('2221', '应交税费', 2, 2, 1),
    ('222101', '应交增值税', 2, 2, 2),
    ('22210101', '进项税额', 2, 2, 3),
    ('22210102', '销项税额', 2, 2, 3),
    ('2241', '其他应付款', 2, 2, 1),
    ('4001', '实收资本', 4, 2, 1),
    ('4002', '资本公积', 4, 2, 1),
    ('4101', '盈余公积', 4, 2, 1),
    ('4103', '本年利润', 4, 2, 1),
    ('4104', '利润分配', 4, 2, 1),
    ('6001', '主营业务收入', 5, 2, 1),
    ('6051', '其他业务收入', 5, 2, 1),
    ('6111', '投资收益', 5, 2, 1),
    ('6301', '营业外收入', 5, 2, 1),
    ('6401', '主营业务成本', 5, 1, 1),
    ('6402', '其他业务成本', 5, 1, 1),
    ('6403', '税金及附加', 5, 1, 1),
    ('6601', '销售费用', 5, 1, 1),
    ('6602', '管理费用', 5, 1, 1),
    ('6603', '财务费用', 5, 1, 1),
    ('6711', '营业外支出', 5, 1, 1),
    ('6801', '所得税费用', 5, 1, 1)
ON CONFLICT (subject_code) DO NOTHING;

-- =============================================
-- 第四部分：触发器
-- =============================================

-- 客户表更新时间触发器
CREATE OR REPLACE FUNCTION update_customers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
CREATE TRIGGER update_customers_updated_at
    BEFORE UPDATE ON public.customers
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- 销售订单表更新时间触发器
CREATE OR REPLACE FUNCTION update_sales_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_sales_orders_updated_at ON public.sales_orders;
CREATE TRIGGER update_sales_orders_updated_at
    BEFORE UPDATE ON public.sales_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_sales_orders_updated_at();

-- 报价单表更新时间触发器
DROP TRIGGER IF EXISTS update_quotations_updated_at ON public.quotations;
CREATE TRIGGER update_quotations_updated_at
    BEFORE UPDATE ON public.quotations
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- 应收账款表更新时间触发器
DROP TRIGGER IF EXISTS update_accounts_receivable_updated_at ON public.accounts_receivable;
CREATE TRIGGER update_accounts_receivable_updated_at
    BEFORE UPDATE ON public.accounts_receivable
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- 应付账款表更新时间触发器
DROP TRIGGER IF EXISTS update_accounts_payable_updated_at ON public.accounts_payable;
CREATE TRIGGER update_accounts_payable_updated_at
    BEFORE UPDATE ON public.accounts_payable
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- 银行账户表更新时间触发器
DROP TRIGGER IF EXISTS update_bank_accounts_updated_at ON public.bank_accounts;
CREATE TRIGGER update_bank_accounts_updated_at
    BEFORE UPDATE ON public.bank_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_customers_updated_at();

-- =============================================
-- 第五部分：视图
-- =============================================

-- 应收账款账龄分析视图
CREATE OR REPLACE VIEW ar_aging_analysis AS
SELECT 
    ar.ar_id,
    ar.ar_no,
    ar.customer_id,
    ar.customer_name,
    ar.ar_date,
    ar.due_date,
    ar.original_amount,
    ar.received_amount,
    ar.remaining_amount,
    ar.status,
    CASE 
        WHEN ar.remaining_amount <= 0 THEN 0
        WHEN CURRENT_DATE <= ar.due_date THEN ar.remaining_amount
        WHEN CURRENT_DATE - ar.due_date <= 30 THEN ar.remaining_amount
        WHEN CURRENT_DATE - ar.due_date <= 60 THEN ar.remaining_amount
        WHEN CURRENT_DATE - ar.due_date <= 90 THEN ar.remaining_amount
        ELSE ar.remaining_amount
    END as current_amount,
    CASE 
        WHEN ar.remaining_amount <= 0 THEN 0
        WHEN CURRENT_DATE <= ar.due_date THEN ar.remaining_amount
        ELSE 0
    END as not_due_amount,
    CASE 
        WHEN ar.remaining_amount > 0 AND CURRENT_DATE - ar.due_date > 0 AND CURRENT_DATE - ar.due_date <= 30 THEN ar.remaining_amount
        ELSE 0
    END as overdue_30,
    CASE 
        WHEN ar.remaining_amount > 0 AND CURRENT_DATE - ar.due_date > 30 AND CURRENT_DATE - ar.due_date <= 60 THEN ar.remaining_amount
        ELSE 0
    END as overdue_60,
    CASE 
        WHEN ar.remaining_amount > 0 AND CURRENT_DATE - ar.due_date > 60 AND CURRENT_DATE - ar.due_date <= 90 THEN ar.remaining_amount
        ELSE 0
    END as overdue_90,
    CASE 
        WHEN ar.remaining_amount > 0 AND CURRENT_DATE - ar.due_date > 90 THEN ar.remaining_amount
        ELSE 0
    END as overdue_over_90
FROM accounts_receivable ar
WHERE ar.status IN (1, 2);

-- 销售统计视图
CREATE OR REPLACE VIEW sales_statistics AS
SELECT 
    so.order_id,
    so.order_no,
    so.customer_id,
    so.customer_name,
    so.order_date,
    so.total_amount,
    so.tax_amount,
    so.final_amount,
    so.order_status,
    so.payment_status,
    so.salesperson,
    COUNT(soi.item_id) as item_count,
    SUM(soi.quantity) as total_quantity
FROM sales_orders so
LEFT JOIN sales_order_items soi ON so.order_id = soi.order_id
GROUP BY so.order_id, so.order_no, so.customer_id, so.customer_name, 
         so.order_date, so.total_amount, so.tax_amount, so.final_amount,
         so.order_status, so.payment_status, so.salesperson;

-- =============================================
-- 完成提示
-- =============================================
SELECT '销售管理与会计核算系统数据库迁移完成' AS result;
