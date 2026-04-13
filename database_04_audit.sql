-- =============================================
-- 销售财务数据隔离与审计 - 数据库迁移脚本
-- 创建时间: 2026-04-06
-- 目标: 实现基于用户的数据隔离和审计日志
-- =============================================

-- =============================================
-- 第一部分：创建缺失的表
-- =============================================

-- 凭证表
CREATE TABLE IF NOT EXISTS public.vouchers (
    voucher_id BIGSERIAL PRIMARY KEY,
    voucher_no VARCHAR(50) UNIQUE NOT NULL,
    voucher_date DATE NOT NULL,
    voucher_type VARCHAR(50),
    description TEXT,
    total_debit DECIMAL(15,2) DEFAULT 0,
    total_credit DECIMAL(15,2) DEFAULT 0,
    status SMALLINT DEFAULT 1,
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vouchers_no ON public.vouchers(voucher_no);
CREATE INDEX IF NOT EXISTS idx_vouchers_date ON public.vouchers(voucher_date);
CREATE INDEX IF NOT EXISTS idx_vouchers_status ON public.vouchers(status);

COMMENT ON TABLE public.vouchers IS '凭证表';
COMMENT ON COLUMN public.vouchers.status IS '状态：1-待审核，2-已审核';

-- 成本记录表
CREATE TABLE IF NOT EXISTS public.cost_records (
    cost_id BIGSERIAL PRIMARY KEY,
    cost_type VARCHAR(50) NOT NULL,
    cost_name VARCHAR(200) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    cost_date DATE NOT NULL,
    remark TEXT,
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cost_records_type ON public.cost_records(cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_date ON public.cost_records(cost_date);

COMMENT ON TABLE public.cost_records IS '成本记录表';

-- 税务汇总表
CREATE TABLE IF NOT EXISTS public.tax_summary (
    tax_id BIGSERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    tax_type VARCHAR(50) NOT NULL,
    tax_base DECIMAL(15,2) DEFAULT 0,
    tax_rate DECIMAL(5,4) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tax_summary_period ON public.tax_summary(period);
CREATE INDEX IF NOT EXISTS idx_tax_summary_type ON public.tax_summary(tax_type);

COMMENT ON TABLE public.tax_summary IS '税务汇总表';

-- 会计期间表
CREATE TABLE IF NOT EXISTS public.accounting_periods (
    period_id BIGSERIAL PRIMARY KEY,
    period VARCHAR(7) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'open',
    checks JSONB,
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_accounting_periods_period ON public.accounting_periods(period);

COMMENT ON TABLE public.accounting_periods IS '会计期间表';

-- =============================================
-- 第二部分：创建审计日志表
-- =============================================

-- 数据访问审计日志表
CREATE TABLE IF NOT EXISTS public.finance_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    username VARCHAR(100),
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT,
    record_no VARCHAR(100),
    operation_type VARCHAR(20) NOT NULL,
    details JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_finance_audit_log_user_id ON public.finance_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_finance_audit_log_created_at ON public.finance_audit_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_finance_audit_log_action ON public.finance_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_finance_audit_log_table ON public.finance_audit_log(table_name);

COMMENT ON TABLE public.finance_audit_log IS '销售财务数据访问审计日志表';
COMMENT ON COLUMN public.finance_audit_log.user_id IS '操作用户ID';
COMMENT ON COLUMN public.finance_audit_log.username IS '操作用户名';
COMMENT ON COLUMN public.finance_audit_log.action_type IS '操作类型: VIEW-查看, CREATE-创建, UPDATE-更新, DELETE-删除, EXPORT-导出';
COMMENT ON COLUMN public.finance_audit_log.table_name IS '操作的表名';
COMMENT ON COLUMN public.finance_audit_log.record_id IS '操作的记录ID';
COMMENT ON COLUMN public.finance_audit_log.record_no IS '操作的记录编号';
COMMENT ON COLUMN public.finance_audit_log.operation_type IS '操作方式: BROWSER-浏览器, API-API调用';
COMMENT ON COLUMN public.finance_audit_log.details IS '操作详情JSON';
COMMENT ON COLUMN public.finance_audit_log.ip_address IS 'IP地址';
COMMENT ON COLUMN public.finance_audit_log.user_agent IS '用户代理';

-- =============================================
-- 第三部分：添加用户ID字段到销售财务相关表
-- =============================================

-- 客户表 - 添加用户ID字段
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON public.customers(user_id);

-- 销售订单表 - 添加用户ID字段
ALTER TABLE public.sales_orders ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_sales_orders_user_id ON public.sales_orders(user_id);

-- 销售订单明细表 - 添加用户ID字段
ALTER TABLE public.sales_order_items ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_user_id ON public.sales_order_items(user_id);

-- 报价单表 - 添加用户ID字段
ALTER TABLE public.quotations ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_quotations_user_id ON public.quotations(user_id);

-- 报价单明细表 - 添加用户ID字段
ALTER TABLE public.quotation_items ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_quotation_items_user_id ON public.quotation_items(user_id);

-- 应收账款表 - 添加用户ID字段
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_user_id ON public.accounts_receivable(user_id);

-- 收款记录表 - 添加用户ID字段
ALTER TABLE public.receipt_records ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_receipt_records_user_id ON public.receipt_records(user_id);

-- 应付账款表 - 添加用户ID字段
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_accounts_payable_user_id ON public.accounts_payable(user_id);

-- 付款记录表 - 添加用户ID字段
ALTER TABLE public.payment_records ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES users(id);
CREATE INDEX IF NOT EXISTS idx_payment_records_user_id ON public.payment_records(user_id);

-- =============================================
-- 第四部分：现有数据分配（将数据分配给admin用户）
-- =============================================

-- 为现有数据设置默认用户ID（假设admin用户ID为1）
UPDATE public.customers SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.sales_orders SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.sales_order_items SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.quotations SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.quotation_items SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.accounts_receivable SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.receipt_records SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.accounts_payable SET user_id = 1 WHERE user_id IS NULL;
UPDATE public.payment_records SET user_id = 1 WHERE user_id IS NULL;

-- =============================================
-- 完成提示
-- =============================================
SELECT '销售财务数据隔离与审计迁移完成' AS result;
