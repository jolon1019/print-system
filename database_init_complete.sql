-- =============================================
-- 热卷打印管理系统 - 完整数据库初始化脚本
-- 整合时间: 2026-03-30
-- 目标数据库: PostgreSQL / Supabase
-- 说明: 此脚本整合了系统所有需要的数据库表结构
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

COMMENT ON TABLE public.user_units IS '用户单位绑定表';
COMMENT ON COLUMN public.user_units.id IS '绑定ID';
COMMENT ON COLUMN public.user_units.user_id IS '用户ID';
COMMENT ON COLUMN public.user_units.unit IS '单位名称';

-- 默认用户数据（密码都是 '123456' 的 bcrypt hash）
INSERT INTO public.users (username, password, real_name, role, status)
VALUES
('admin', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '系统管理员', 'admin', 1),
('user1', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '张三', 'user', 1),
('user2', '$2b$10$K7kaNFKT7uukEoc1sNnfJe4sVzHXkEDotceA9odYVjb.W12Yz.N6C', '李四', 'user', 1)
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

-- =============================================
-- 第三部分：财务系统表
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
INSERT INTO public.accounting_subjects (subject_code, subject_name, subject_type, balance_direction)
VALUES
    ('1001', '库存现金', 1, 1),
    ('1002', '银行存款', 1, 1),
    ('1122', '应收账款', 1, 1),
    ('1405', '库存商品', 1, 1),
    ('2202', '应付账款', 2, 2),
    ('6001', '主营业务收入', 5, 2),
    ('6401', '主营业务成本', 5, 1),
    ('6601', '销售费用', 5, 1),
    ('6602', '管理费用', 5, 1)
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
-- 第四部分：货权转让表
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
-- 第五部分：函数和触发器
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

-- =============================================
-- 第六部分：视图
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

-- =============================================
-- 完成提示
-- =============================================
SELECT '数据库初始化完成' AS result;
