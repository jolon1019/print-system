-- =============================================
-- 热卷打印管理系统 - 完整数据库架构
-- 整合时间: 2026-04-09
-- 目标数据库: PostgreSQL / Supabase
-- 说明: 此脚本整合了系统所有数据库表结构
-- =============================================

-- =============================================
-- 第一部分：用户系统
-- =============================================

-- 用户表
CREATE TABLE IF NOT EXISTS public.users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  real_name VARCHAR(50) NOT NULL,
  role VARCHAR(20) NOT NULL DEFAULT 'user',
  status SMALLINT NOT NULL DEFAULT 1,
  can_transfer BOOLEAN NOT NULL DEFAULT TRUE,
  can_view_finance BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用户单位绑定表
CREATE TABLE IF NOT EXISTS public.user_units (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  unit VARCHAR(50) NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, unit)
);

-- 用户表索引
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);
CREATE INDEX IF NOT EXISTS idx_user_units_user_id ON public.user_units(user_id);
CREATE INDEX IF NOT EXISTS idx_user_units_unit ON public.user_units(unit);

-- 用户表注释
COMMENT ON TABLE public.users IS '用户表';
COMMENT ON COLUMN public.users.id IS '用户ID';
COMMENT ON COLUMN public.users.username IS '用户名';
COMMENT ON COLUMN public.users.password IS '密码（bcrypt加密）';
COMMENT ON COLUMN public.users.real_name IS '真实姓名';
COMMENT ON COLUMN public.users.role IS '角色：admin-管理员，user-普通用户';
COMMENT ON COLUMN public.users.status IS '状态：1-启用，0-禁用';
COMMENT ON COLUMN public.users.can_transfer IS '货权转让权限：true-可转让，false-不可转让';
COMMENT ON COLUMN public.users.can_view_finance IS '财务查看权限：true-可查看，false-不可查看';

COMMENT ON TABLE public.user_units IS '用户单位绑定表';
COMMENT ON COLUMN public.user_units.id IS '绑定ID';
COMMENT ON COLUMN public.user_units.user_id IS '用户ID';
COMMENT ON COLUMN public.user_units.unit IS '单位名称';

-- 默认用户数据（密码都是 '123456' 的 bcrypt hash）
INSERT INTO public.users (username, password, real_name, role, status, can_view_finance)
VALUES
('admin', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '系统管理员', 'admin', 1, true),
('user1', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '张三', 'user', 1, false),
('user2', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '李四', 'user', 1, false)
ON CONFLICT (username) DO NOTHING;

-- =============================================
-- 第二部分：核心业务表
-- =============================================

-- 库存表 (inventory)
CREATE TABLE IF NOT EXISTS public.inventory (
    id BIGSERIAL PRIMARY KEY,
    batch_no VARCHAR(50) NOT NULL UNIQUE,
    unit VARCHAR(20) NOT NULL,
    specification VARCHAR(100) NOT NULL,
    material VARCHAR(50) NOT NULL,
    weight DECIMAL(15,3) NOT NULL,
    vehicle_no VARCHAR(20),
    transport_fee DECIMAL(10,2) DEFAULT 0.00,
    advance_payment DECIMAL(10,2) DEFAULT 0.00,
    storage_location VARCHAR(100) NOT NULL,
    in_date DATE NOT NULL,
    status SMALLINT DEFAULT 1,
    remark TEXT,
    transfer_ref TEXT,
    original_inventory_id BIGINT,
    is_listed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 库存表索引
CREATE INDEX IF NOT EXISTS idx_inventory_batch_no ON public.inventory(batch_no);
CREATE INDEX IF NOT EXISTS idx_inventory_material ON public.inventory(material);
CREATE INDEX IF NOT EXISTS idx_inventory_specification ON public.inventory(specification);
CREATE INDEX IF NOT EXISTS idx_inventory_in_date ON public.inventory(in_date);
CREATE INDEX IF NOT EXISTS idx_inventory_status ON public.inventory(status);
CREATE INDEX IF NOT EXISTS idx_inventory_storage_location ON public.inventory(storage_location);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_ref ON public.inventory(transfer_ref);
CREATE INDEX IF NOT EXISTS idx_inventory_original_id ON public.inventory(original_inventory_id);
CREATE INDEX IF NOT EXISTS idx_inventory_is_listed ON public.inventory(is_listed);

-- 库存表注释
COMMENT ON TABLE public.inventory IS '库存主表';
COMMENT ON COLUMN public.inventory.id IS '主键标识';
COMMENT ON COLUMN public.inventory.batch_no IS '批号，唯一标识符';
COMMENT ON COLUMN public.inventory.unit IS '单位（如：吨、公斤、件）';
COMMENT ON COLUMN public.inventory.specification IS '规格描述';
COMMENT ON COLUMN public.inventory.material IS '材料类型';
COMMENT ON COLUMN public.inventory.weight IS '入库重量';
COMMENT ON COLUMN public.inventory.vehicle_no IS '入库车牌号';
COMMENT ON COLUMN public.inventory.transport_fee IS '运输费用';
COMMENT ON COLUMN public.inventory.advance_payment IS '预付款';
COMMENT ON COLUMN public.inventory.storage_location IS '存储位置';
COMMENT ON COLUMN public.inventory.in_date IS '入库日期';
COMMENT ON COLUMN public.inventory.status IS '状态：1-在库 2-已出库 3-冻结';
COMMENT ON COLUMN public.inventory.remark IS '备注信息';
COMMENT ON COLUMN public.inventory.transfer_ref IS '货权转让关联单号';
COMMENT ON COLUMN public.inventory.original_inventory_id IS '原始库存ID（货权转让来源）';
COMMENT ON COLUMN public.inventory.is_listed IS '是否上架到小程序：true-已上架，false-未上架';

-- 出库表 (outbound)
CREATE TABLE IF NOT EXISTS public.outbound (
    outbound_order_id BIGSERIAL PRIMARY KEY,
    inventory_id BIGINT NOT NULL,
    batch_no VARCHAR(50) NOT NULL,
    material VARCHAR(50) NOT NULL,
    specification VARCHAR(100) NOT NULL,
    stock_weight DECIMAL(15,3) NOT NULL,
    out_weight DECIMAL(15,3) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    out_type SMALLINT DEFAULT 1,
    out_date DATE NOT NULL,
    vehicle_no VARCHAR(60),
    remark TEXT,
    ref_no TEXT,
    unit VARCHAR(50),
    transfer_ref TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_outbound_inventory FOREIGN KEY (inventory_id) REFERENCES inventory(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 出库表索引
CREATE INDEX IF NOT EXISTS idx_outbound_inventory_id ON public.outbound(inventory_id);
CREATE INDEX IF NOT EXISTS idx_outbound_batch_no ON public.outbound(batch_no);
CREATE INDEX IF NOT EXISTS idx_outbound_out_date ON public.outbound(out_date);
CREATE INDEX IF NOT EXISTS idx_outbound_out_type ON public.outbound(out_type);
CREATE INDEX IF NOT EXISTS idx_outbound_material ON public.outbound(material);
CREATE INDEX IF NOT EXISTS idx_outbound_ref_no ON public.outbound(ref_no);
CREATE INDEX IF NOT EXISTS idx_outbound_unit ON public.outbound(unit);
CREATE INDEX IF NOT EXISTS idx_outbound_transfer_ref ON public.outbound(transfer_ref);

-- 出库表注释
COMMENT ON TABLE public.outbound IS '出库记录表';
COMMENT ON COLUMN public.outbound.outbound_order_id IS '出库记录唯一标识';
COMMENT ON COLUMN public.outbound.inventory_id IS '关联库存记录ID';
COMMENT ON COLUMN public.outbound.batch_no IS '批号，冗余存储便于查询';
COMMENT ON COLUMN public.outbound.material IS '材料类型';
COMMENT ON COLUMN public.outbound.specification IS '规格描述';
COMMENT ON COLUMN public.outbound.stock_weight IS '出库前库存重量';
COMMENT ON COLUMN public.outbound.out_weight IS '出库重量';
COMMENT ON COLUMN public.outbound.unit_price IS '单价';
COMMENT ON COLUMN public.outbound.total_amount IS '总金额';
COMMENT ON COLUMN public.outbound.out_type IS '出库类型：1-加工，2-装卷，3-销售，4-货权转让';
COMMENT ON COLUMN public.outbound.out_date IS '出库日期';
COMMENT ON COLUMN public.outbound.vehicle_no IS '出库车牌号';
COMMENT ON COLUMN public.outbound.remark IS '出库备注';
COMMENT ON COLUMN public.outbound.ref_no IS '出库单号，格式：OUTYYYYMMDDXXX';
COMMENT ON COLUMN public.outbound.unit IS '出库时的单位（对于货权转让，记录原单位）';
COMMENT ON COLUMN public.outbound.transfer_ref IS '货权转让关联单号';

-- 出库类型配置表 (outbound_types)
CREATE TABLE IF NOT EXISTS public.outbound_types (
    id BIGSERIAL PRIMARY KEY,
    type_code SMALLINT NOT NULL UNIQUE,
    type_name VARCHAR(50) NOT NULL,
    tag_type VARCHAR(20) DEFAULT 'info',
    sort_order SMALLINT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMENT ON TABLE public.outbound_types IS '出库类型配置表';
COMMENT ON COLUMN public.outbound_types.type_code IS '类型编码：1-加工，2-装卷，3-销售等';
COMMENT ON COLUMN public.outbound_types.type_name IS '类型显示名称';
COMMENT ON COLUMN public.outbound_types.tag_type IS 'Element Plus Tag类型：success/primary/info/warning/danger';
COMMENT ON COLUMN public.outbound_types.sort_order IS '排序顺序，越小越靠前';
COMMENT ON COLUMN public.outbound_types.is_active IS '是否启用';

-- 出库类型初始数据
INSERT INTO public.outbound_types (type_code, type_name, tag_type, sort_order, is_active) VALUES
    (1, '加工', 'success', 1, TRUE),
    (2, '装卷', 'primary', 2, TRUE),
    (3, '销售', 'info', 3, TRUE),
    (4, '货权转让', 'warning', 4, TRUE)
ON CONFLICT (type_code) DO NOTHING;

-- 团队备注表 (team_notes)
CREATE TABLE IF NOT EXISTS public.team_notes (
  id TEXT NOT NULL,
  a_team TEXT DEFAULT '',
  b_team TEXT DEFAULT '',
  c_team TEXT DEFAULT '',
  outbound_orders JSONB DEFAULT '[]'::jsonb,
  outbound_batches JSONB DEFAULT '[]'::jsonb,
  coil_inventory JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT team_notes_pkey PRIMARY KEY (id)
);

-- 团队备注表索引
CREATE INDEX IF NOT EXISTS idx_team_notes_outbound_orders ON public.team_notes USING gin (outbound_orders);
CREATE INDEX IF NOT EXISTS idx_team_notes_outbound_batches ON public.team_notes USING gin (outbound_batches);
CREATE INDEX IF NOT EXISTS idx_team_notes_coil_inventory ON public.team_notes USING gin (coil_inventory);

-- 虚拟库存表（邯钢现货）
CREATE TABLE IF NOT EXISTS public.virtual_inventory (
    id BIGSERIAL PRIMARY KEY,
    batch_no VARCHAR(50) NOT NULL UNIQUE,
    material VARCHAR(50) NOT NULL,
    specification VARCHAR(100) NOT NULL,
    weight DECIMAL(15,3) NOT NULL DEFAULT 0,
    unit_price DECIMAL(10,2) DEFAULT 0,
    source VARCHAR(100),
    location VARCHAR(100),
    status SMALLINT NOT NULL DEFAULT 1,
    remark TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_virtual_inventory_batch_no ON public.virtual_inventory(batch_no);
CREATE INDEX IF NOT EXISTS idx_virtual_inventory_material ON public.virtual_inventory(material);
CREATE INDEX IF NOT EXISTS idx_virtual_inventory_status ON public.virtual_inventory(status);
CREATE INDEX IF NOT EXISTS idx_virtual_inventory_created_at ON public.virtual_inventory(created_at DESC);

COMMENT ON TABLE public.virtual_inventory IS '虚拟库存表（邯钢现货）- 与实际库存完全隔离';
COMMENT ON COLUMN public.virtual_inventory.id IS '主键ID';
COMMENT ON COLUMN public.virtual_inventory.batch_no IS '批号（唯一标识）';
COMMENT ON COLUMN public.virtual_inventory.material IS '材质（如Q235B、Q355B）';
COMMENT ON COLUMN public.virtual_inventory.specification IS '规格（如3.0*1250*C）';
COMMENT ON COLUMN public.virtual_inventory.weight IS '重量（单位：吨）';
COMMENT ON COLUMN public.virtual_inventory.unit_price IS '单价（单位：元/吨）';
COMMENT ON COLUMN public.virtual_inventory.source IS '来源（如邯钢本部、邯钢新区）';
COMMENT ON COLUMN public.virtual_inventory.location IS '存放地（如邯郸、天津）';
COMMENT ON COLUMN public.virtual_inventory.status IS '状态：1-可用，0-已锁定';
COMMENT ON COLUMN public.virtual_inventory.remark IS '备注信息';

-- 价格调整日志表
CREATE TABLE IF NOT EXISTS public.price_adjustment_logs (
    id BIGSERIAL PRIMARY KEY,
    batch_no VARCHAR(100) NOT NULL,
    old_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    new_price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    adjust_mode VARCHAR(20) NOT NULL,
    adjust_value DECIMAL(12, 2) NOT NULL,
    operator VARCHAR(100),
    operation_time TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    operation_type VARCHAR(50) DEFAULT 'batch_price_adjustment'
);

CREATE INDEX IF NOT EXISTS idx_price_adjustment_logs_batch_no ON public.price_adjustment_logs(batch_no);
CREATE INDEX IF NOT EXISTS idx_price_adjustment_logs_operation_time ON public.price_adjustment_logs(operation_time);
CREATE INDEX IF NOT EXISTS idx_price_adjustment_logs_operator ON public.price_adjustment_logs(operator);

COMMENT ON TABLE public.price_adjustment_logs IS '价格调整日志表';
COMMENT ON COLUMN public.price_adjustment_logs.batch_no IS '批号';
COMMENT ON COLUMN public.price_adjustment_logs.old_price IS '调整前单价(元/吨)';
COMMENT ON COLUMN public.price_adjustment_logs.new_price IS '调整后单价(元/吨)';
COMMENT ON COLUMN public.price_adjustment_logs.adjust_mode IS '调整方式: add-增加, subtract-减少';
COMMENT ON COLUMN public.price_adjustment_logs.adjust_value IS '调整值';
COMMENT ON COLUMN public.price_adjustment_logs.operator IS '操作人';
COMMENT ON COLUMN public.price_adjustment_logs.operation_time IS '操作时间';
COMMENT ON COLUMN public.price_adjustment_logs.operation_type IS '操作类型';

-- =============================================
-- 第三部分：货权转让表
-- =============================================

-- 货权转让表 (inventory_transfer)
CREATE TABLE IF NOT EXISTS public.inventory_transfer (
  id BIGSERIAL PRIMARY KEY,
  inventory_id BIGINT NOT NULL REFERENCES inventory(id) ON DELETE CASCADE,
  batch_no VARCHAR(50) NOT NULL,
  from_unit VARCHAR(50) NOT NULL,
  to_unit VARCHAR(50) NOT NULL,
  transfer_date TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  transfer_reason TEXT,
  operator_id BIGINT REFERENCES users(id),
  operator_name VARCHAR(50),
  status SMALLINT NOT NULL DEFAULT 1,
  remark TEXT,
  new_inventory_id BIGINT,
  transfer_ref TEXT,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 货权转让表索引
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_inventory_id ON public.inventory_transfer(inventory_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_batch_no ON public.inventory_transfer(batch_no);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_from_unit ON public.inventory_transfer(from_unit);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_to_unit ON public.inventory_transfer(to_unit);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_transfer_date ON public.inventory_transfer(transfer_date);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_operator_id ON public.inventory_transfer(operator_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_status ON public.inventory_transfer(status);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_new_id ON public.inventory_transfer(new_inventory_id);
CREATE INDEX IF NOT EXISTS idx_inventory_transfer_ref ON public.inventory_transfer(transfer_ref);

-- 货权转让表注释
COMMENT ON TABLE public.inventory_transfer IS '货权转让表';
COMMENT ON COLUMN public.inventory_transfer.id IS '转让ID';
COMMENT ON COLUMN public.inventory_transfer.inventory_id IS '库存ID';
COMMENT ON COLUMN public.inventory_transfer.batch_no IS '批号';
COMMENT ON COLUMN public.inventory_transfer.from_unit IS '转让单位';
COMMENT ON COLUMN public.inventory_transfer.to_unit IS '接收单位';
COMMENT ON COLUMN public.inventory_transfer.transfer_date IS '转让时间';
COMMENT ON COLUMN public.inventory_transfer.transfer_reason IS '转让原因';
COMMENT ON COLUMN public.inventory_transfer.operator_id IS '操作人ID';
COMMENT ON COLUMN public.inventory_transfer.operator_name IS '操作人姓名';
COMMENT ON COLUMN public.inventory_transfer.status IS '状态：1-已完成，2-已取消';
COMMENT ON COLUMN public.inventory_transfer.remark IS '备注';
COMMENT ON COLUMN public.inventory_transfer.new_inventory_id IS '转让后新建的库存记录ID';
COMMENT ON COLUMN public.inventory_transfer.transfer_ref IS '货权转让关联单号';

-- =============================================
-- 第四部分：财务系统表
-- =============================================

-- 财务台账表 (finance_ledger)
CREATE TABLE IF NOT EXISTS public.finance_ledger (
  ledger_id SERIAL PRIMARY KEY,
  ref_no VARCHAR(50) NOT NULL UNIQUE,
  transaction_date DATE NOT NULL,
  transaction_time TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  transaction_type VARCHAR(20) NOT NULL,
  transaction_category VARCHAR(50),
  description TEXT,
  unit VARCHAR(10) DEFAULT '元',
  amount DECIMAL(15,2) NOT NULL,
  tax_amount DECIMAL(15,2) DEFAULT 0,
  total_amount DECIMAL(15,2) NOT NULL,
  outbound_order_id INTEGER,
  customer_supplier VARCHAR(100),
  batch_no VARCHAR(50),
  quantity DECIMAL(10,3),
  unit_price DECIMAL(10,2),
  debit_account VARCHAR(50),
  credit_account VARCHAR(50),
  payment_method VARCHAR(20),
  bank_account VARCHAR(50),
  status VARCHAR(20) DEFAULT 'pending',
  is_reconciled BOOLEAN DEFAULT FALSE,
  created_by VARCHAR(50),
  approved_by VARCHAR(50),
  approved_at TIMESTAMP WITHOUT TIME ZONE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  modification_reason TEXT,
  sync_source VARCHAR(50) DEFAULT 'manual',
  sync_status VARCHAR(20) DEFAULT 'pending',
  sync_attempts INTEGER DEFAULT 0,
  last_sync_time TIMESTAMP WITHOUT TIME ZONE,
  is_deleted BOOLEAN DEFAULT FALSE,
  CONSTRAINT finance_ledger_outbound_order_id_fkey FOREIGN KEY (outbound_order_id) REFERENCES outbound(outbound_order_id)
);

-- 财务台账表索引
CREATE INDEX IF NOT EXISTS idx_finance_ledger_sync_source ON public.finance_ledger(sync_source);

-- 日常记账表 (daily_accounting)
CREATE TABLE IF NOT EXISTS public.daily_accounting (
  daily_id SERIAL PRIMARY KEY,
  accounting_date DATE NOT NULL UNIQUE,
  summary VARCHAR(200),
  description TEXT,
  total_income DECIMAL(15,2) DEFAULT 0,
  total_expense DECIMAL(15,2) DEFAULT 0,
  total_transactions INTEGER DEFAULT 0,
  is_closed BOOLEAN DEFAULT FALSE,
  closed_by VARCHAR(50),
  closed_at TIMESTAMP WITHOUT TIME ZONE,
  reviewed_by VARCHAR(50),
  reviewed_at TIMESTAMP WITHOUT TIME ZONE,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 会计科目表 (accounting_subjects)
CREATE TABLE IF NOT EXISTS public.accounting_subjects (
    subject_id BIGSERIAL PRIMARY KEY,
    subject_code VARCHAR(20) NOT NULL UNIQUE,
    subject_name VARCHAR(100) NOT NULL,
    subject_level SMALLINT DEFAULT 1,
    parent_id BIGINT,
    subject_type SMALLINT NOT NULL,
    balance_direction SMALLINT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 会计科目表索引
CREATE INDEX IF NOT EXISTS idx_subjects_code ON public.accounting_subjects(subject_code);
CREATE INDEX IF NOT EXISTS idx_subjects_parent ON public.accounting_subjects(parent_id);
CREATE INDEX IF NOT EXISTS idx_subjects_type ON public.accounting_subjects(subject_type);

-- 基础会计科目数据
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

-- 收支分类表 (income_expense_categories)
CREATE TABLE IF NOT EXISTS public.income_expense_categories (
    category_id BIGSERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    category_type SMALLINT NOT NULL,
    parent_id BIGINT,
    category_level SMALLINT DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 基础收支分类数据
INSERT INTO public.income_expense_categories (category_name, category_type)
VALUES
    ('销售收入', 1),
    ('其他收入', 1),
    ('采购成本', 2),
    ('运输费用', 2),
    ('人工成本', 2),
    ('办公费用', 2)
ON CONFLICT DO NOTHING;

-- 对账记录表 (reconciliation_records)
CREATE TABLE IF NOT EXISTS public.reconciliation_records (
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
    FOREIGN KEY (outbound_order_id) REFERENCES outbound(outbound_order_id) ON DELETE RESTRICT
);

-- 对账记录表索引
CREATE INDEX IF NOT EXISTS idx_reconciliation_outbound ON public.reconciliation_records(outbound_order_id);
CREATE INDEX IF NOT EXISTS idx_reconciliation_date ON public.reconciliation_records(reconciliation_date);
CREATE INDEX IF NOT EXISTS idx_reconciliation_status ON public.reconciliation_records(reconciliation_status);

-- 会计凭证表 (accounting_vouchers)
CREATE TABLE IF NOT EXISTS public.accounting_vouchers (
    voucher_id BIGSERIAL PRIMARY KEY,
    voucher_no VARCHAR(50) NOT NULL UNIQUE,
    voucher_date DATE NOT NULL,
    voucher_type SMALLINT NOT NULL,
    summary TEXT,
    total_debit DECIMAL(12,2) DEFAULT 0.00,
    total_credit DECIMAL(12,2) DEFAULT 0.00,
    prepared_by VARCHAR(50),
    reviewed_by VARCHAR(50),
    posted BOOLEAN DEFAULT FALSE,
    posted_at TIMESTAMP,
    reconciliation_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reconciliation_id) REFERENCES reconciliation_records(reconciliation_id) ON DELETE SET NULL
);

-- 会计凭证表索引
CREATE INDEX IF NOT EXISTS idx_vouchers_no ON public.accounting_vouchers(voucher_no);
CREATE INDEX IF NOT EXISTS idx_vouchers_date ON public.accounting_vouchers(voucher_date);
CREATE INDEX IF NOT EXISTS idx_vouchers_type ON public.accounting_vouchers(voucher_type);
CREATE INDEX IF NOT EXISTS idx_vouchers_reconciliation ON public.accounting_vouchers(reconciliation_id);

-- 凭证明细表 (voucher_items)
CREATE TABLE IF NOT EXISTS public.voucher_items (
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

-- 凭证明细表索引
CREATE INDEX IF NOT EXISTS idx_items_voucher ON public.voucher_items(voucher_id);
CREATE INDEX IF NOT EXISTS idx_items_subject ON public.voucher_items(subject_id);

-- 财务汇总表 (financial_summary)
CREATE TABLE IF NOT EXISTS public.financial_summary (
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

-- 财务汇总表索引
CREATE INDEX IF NOT EXISTS idx_summary_date ON public.financial_summary(summary_date);
CREATE INDEX IF NOT EXISTS idx_summary_type ON public.financial_summary(summary_type);

-- =============================================
-- 第五部分：销售管理系统表
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
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(customer_code);
CREATE INDEX IF NOT EXISTS idx_customers_name ON public.customers(customer_name);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_type ON public.customers(customer_type);
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON public.customers(user_id);

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
    user_id BIGINT REFERENCES users(id),
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
CREATE INDEX IF NOT EXISTS idx_sales_orders_user_id ON public.sales_orders(user_id);

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
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sales_order_items_order ON public.sales_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_inventory ON public.sales_order_items(inventory_id);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_batch ON public.sales_order_items(batch_no);
CREATE INDEX IF NOT EXISTS idx_sales_order_items_user_id ON public.sales_order_items(user_id);

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
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotations_no ON public.quotations(quotation_no);
CREATE INDEX IF NOT EXISTS idx_quotations_customer ON public.quotations(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotations_date ON public.quotations(quotation_date);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON public.quotations(status);
CREATE INDEX IF NOT EXISTS idx_quotations_user_id ON public.quotations(user_id);

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
    user_id BIGINT REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotation_items_quotation ON public.quotation_items(quotation_id);
CREATE INDEX IF NOT EXISTS idx_quotation_items_user_id ON public.quotation_items(user_id);

-- =============================================
-- 第六部分：应收应付账款表
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
    user_id BIGINT REFERENCES users(id),
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
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_user_id ON public.accounts_receivable(user_id);

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
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_receipt_no ON public.receipt_records(receipt_no);
CREATE INDEX IF NOT EXISTS idx_receipt_ar ON public.receipt_records(ar_id);
CREATE INDEX IF NOT EXISTS idx_receipt_customer ON public.receipt_records(customer_id);
CREATE INDEX IF NOT EXISTS idx_receipt_date ON public.receipt_records(receipt_date);
CREATE INDEX IF NOT EXISTS idx_receipt_records_user_id ON public.receipt_records(user_id);

COMMENT ON TABLE public.receipt_records IS '收款记录表';
COMMENT ON COLUMN public.receipt_records.payment_method IS '付款方式：cash-现金，bank_transfer-银行转账，alipay-支付宝，wechat-微信';

-- 应付账款表
CREATE TABLE IF NOT EXISTS public.accounts_payable (
    ap_id SERIAL PRIMARY KEY,
    ap_no VARCHAR(50) UNIQUE NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_id BIGINT,
    inventory_id BIGINT REFERENCES inventory(id),
    batch_no VARCHAR(50),
    ap_date DATE NOT NULL,
    due_date DATE,
    original_amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2),
    invoice_status SMALLINT DEFAULT 0,
    invoice_no VARCHAR(50),
    invoice_date DATE,
    invoice_amount DECIMAL(15,2),
    status INTEGER DEFAULT 1,
    remark TEXT,
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ap_no ON public.accounts_payable(ap_no);
CREATE INDEX IF NOT EXISTS idx_ap_supplier ON public.accounts_payable(supplier_name);
CREATE INDEX IF NOT EXISTS idx_ap_date ON public.accounts_payable(ap_date);
CREATE INDEX IF NOT EXISTS idx_ap_status ON public.accounts_payable(status);
CREATE INDEX IF NOT EXISTS idx_accounts_payable_user_id ON public.accounts_payable(user_id);

COMMENT ON TABLE public.accounts_payable IS '应付账款表';
COMMENT ON COLUMN public.accounts_payable.status IS '状态：1-未付款，2-部分付款，3-已结清';

-- 付款记录表
CREATE TABLE IF NOT EXISTS public.payment_records (
    payment_id SERIAL PRIMARY KEY,
    payment_no VARCHAR(50) UNIQUE,
    ap_id INTEGER REFERENCES accounts_payable(ap_id),
    supplier_name VARCHAR(100),
    payment_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50),
    bank_account_id INTEGER REFERENCES bank_accounts(account_id),
    voucher_no VARCHAR(50),
    remark TEXT,
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_no ON public.payment_records(payment_no);
CREATE INDEX IF NOT EXISTS idx_payment_ap ON public.payment_records(ap_id);
CREATE INDEX IF NOT EXISTS idx_payment_date ON public.payment_records(payment_date);
CREATE INDEX IF NOT EXISTS idx_payment_records_user_id ON public.payment_records(user_id);

COMMENT ON TABLE public.payment_records IS '付款记录表';

-- =============================================
-- 第七部分：成本核算与税务管理表
-- =============================================

-- 供应商表
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

-- 成本记录表
CREATE TABLE IF NOT EXISTS public.cost_records (
    cost_id BIGSERIAL PRIMARY KEY,
    cost_type VARCHAR(50) NOT NULL,
    cost_name VARCHAR(200) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    cost_date DATE NOT NULL,
    product_id INTEGER,
    department VARCHAR(100),
    remark TEXT,
    user_id BIGINT REFERENCES users(id),
    created_by VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cost_records_type ON public.cost_records(cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_records_date ON public.cost_records(cost_date);

COMMENT ON TABLE public.cost_records IS '成本记录表';
COMMENT ON COLUMN public.cost_records.cost_type IS '成本类型：material-材料，labor-人工，manufacturing-制造，admin-管理，sales-销售，other-其他';

-- 产品成本表
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

-- 发票管理表
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

-- 增值税记录表
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

-- 附加税记录表
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

-- 企业所得税记录表
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

-- 税款缴纳记录表
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

-- =============================================
-- 第八部分：会计期间与结账表
-- =============================================

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
COMMENT ON COLUMN public.accounting_periods.status IS '状态：open-开放，closed-已结账';

-- 科目余额表
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

-- 结账审计日志表
CREATE TABLE IF NOT EXISTS public.closing_audit_log (
    log_id SERIAL PRIMARY KEY,
    period VARCHAR(7) NOT NULL,
    action VARCHAR(200) NOT NULL,
    operator VARCHAR(100),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE public.closing_audit_log IS '结账审计日志表';

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

-- =============================================
-- 第九部分：审计日志表
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
-- 第十部分：函数和触发器
-- =============================================

-- 更新时间戳函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 更新库存状态函数（货权转让时不修改库存状态）
CREATE OR REPLACE FUNCTION update_inventory_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.out_type = 4 THEN
        RETURN NEW;
    END IF;
    
    UPDATE inventory 
    SET status = 2, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.inventory_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 用户表更新时间触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON public.users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 团队备注表更新时间触发器
DROP TRIGGER IF EXISTS update_team_notes_updated_at ON public.team_notes;
CREATE TRIGGER update_team_notes_updated_at
BEFORE UPDATE ON public.team_notes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 货权转让表更新时间触发器
DROP TRIGGER IF EXISTS update_inventory_transfer_updated_at ON public.inventory_transfer;
CREATE TRIGGER update_inventory_transfer_updated_at
BEFORE UPDATE ON public.inventory_transfer
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 出库后更新库存状态触发器
DROP TRIGGER IF EXISTS after_outbound_insert ON public.outbound;
CREATE TRIGGER after_outbound_insert
AFTER INSERT ON public.outbound
FOR EACH ROW
EXECUTE FUNCTION update_inventory_status();

-- 虚拟库存表更新时间触发器
CREATE OR REPLACE FUNCTION update_virtual_inventory_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_virtual_inventory_updated_at ON public.virtual_inventory;
CREATE TRIGGER update_virtual_inventory_updated_at
    BEFORE UPDATE ON public.virtual_inventory
    FOR EACH ROW
    EXECUTE FUNCTION update_virtual_inventory_updated_at();

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
-- 第十一部分：视图
-- =============================================

-- 当前有效库存视图
CREATE OR REPLACE VIEW current_inventory AS
SELECT 
    i.id,
    i.batch_no,
    i.unit,
    i.specification,
    i.material,
    i.weight,
    i.storage_location,
    i.in_date,
    i.status,
    i.created_at
FROM inventory i
WHERE i.status = 1
ORDER BY i.in_date DESC, i.batch_no;

-- 出库统计视图
CREATE OR REPLACE VIEW outbound_summary AS
SELECT 
    o.outbound_order_id,
    o.batch_no,
    o.material,
    o.specification,
    o.out_weight,
    o.unit_price,
    o.total_amount,
    o.out_date,
    o.out_type,
    i.storage_location as original_storage
FROM outbound o
JOIN inventory i ON o.inventory_id = i.id
ORDER BY o.out_date DESC;

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
SELECT '数据库架构初始化完成' AS result;
