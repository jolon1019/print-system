-- 规范化库存管理系统数据库结构（PostgreSQL/Supabase兼容版）
-- 创建时间: 2025-12-20
-- 设计原则: 符合数据库规范化原则（1NF, 2NF, 3NF），避免数据冗余和异常

-- =============================================
-- 1. 库存表 (inventory) - 主表
-- =============================================
CREATE TABLE inventory (
    -- 主键标识
    id BIGSERIAL PRIMARY KEY,
    
    -- 核心业务字段
    batch_no VARCHAR(50) NOT NULL UNIQUE,
    unit VARCHAR(20) NOT NULL,
    specification VARCHAR(100) NOT NULL,
    material VARCHAR(50) NOT NULL,
    
    -- 重量信息
    weight DECIMAL(15,3) NOT NULL,
    
    -- 物流信息
    vehicle_no VARCHAR(20),
    transport_fee DECIMAL(10,2) DEFAULT 0.00,
    advance_payment DECIMAL(10,2) DEFAULT 0.00,
    
    -- 存储信息
    storage_location VARCHAR(100) NOT NULL,
    in_date DATE NOT NULL,
    
    -- 状态管理
    status SMALLINT DEFAULT 1,
    
    -- 备注信息
    remark TEXT,
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 为库存表创建索引
CREATE INDEX idx_inventory_batch_no ON inventory(batch_no);
CREATE INDEX idx_inventory_material ON inventory(material);
CREATE INDEX idx_inventory_specification ON inventory(specification);
CREATE INDEX idx_inventory_in_date ON inventory(in_date);
CREATE INDEX idx_inventory_status ON inventory(status);
CREATE INDEX idx_inventory_storage_location ON inventory(storage_location);

-- 添加表注释（PostgreSQL方式）
COMMENT ON TABLE inventory IS '库存主表';
COMMENT ON COLUMN inventory.id IS '主键标识';
COMMENT ON COLUMN inventory.batch_no IS '批号，唯一标识符';
COMMENT ON COLUMN inventory.unit IS '单位（如：吨、公斤、件）';
COMMENT ON COLUMN inventory.specification IS '规格描述';
COMMENT ON COLUMN inventory.material IS '材料类型';
COMMENT ON COLUMN inventory.weight IS '入库重量';
COMMENT ON COLUMN inventory.vehicle_no IS '入库车牌号';
COMMENT ON COLUMN inventory.transport_fee IS '运输费用';
COMMENT ON COLUMN inventory.advance_payment IS '预付款';
COMMENT ON COLUMN inventory.storage_location IS '存储位置';
COMMENT ON COLUMN inventory.in_date IS '入库日期';
COMMENT ON COLUMN inventory.status IS '状态：1-在库 2-已出库 3-冻结';
COMMENT ON COLUMN inventory.remark IS '备注信息';
COMMENT ON COLUMN inventory.created_at IS '创建时间';
COMMENT ON COLUMN inventory.updated_at IS '更新时间';

-- =============================================
-- 2. 出库表 (outbound) - 关联表
-- =============================================
CREATE TABLE outbound (
    -- 主键标识
    outbound_order_id BIGSERIAL PRIMARY KEY,
    
    -- 关联字段
    inventory_id BIGINT NOT NULL,
    batch_no VARCHAR(50) NOT NULL,
    
    -- 产品信息（冗余存储，避免频繁联表查询）
    material VARCHAR(50) NOT NULL,
    specification VARCHAR(100) NOT NULL,
    
    -- 重量信息
    stock_weight DECIMAL(15,3) NOT NULL,
    out_weight DECIMAL(15,3) NOT NULL,
    
    -- 财务信息
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    
    -- 出库业务信息
    out_type SMALLINT DEFAULT 1,
    out_date DATE NOT NULL,
    
    -- 物流信息
    vehicle_no VARCHAR(20),
    
    -- 备注信息
    remark TEXT,
    
    -- 系统字段
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 为出库表创建外键约束
ALTER TABLE outbound 
ADD CONSTRAINT fk_outbound_inventory 
FOREIGN KEY (inventory_id) 
REFERENCES inventory(id) 
ON DELETE RESTRICT 
ON UPDATE CASCADE;

-- 为出库表创建索引
CREATE INDEX idx_outbound_inventory_id ON outbound(inventory_id);
CREATE INDEX idx_outbound_batch_no ON outbound(batch_no);
CREATE INDEX idx_outbound_out_date ON outbound(out_date);
CREATE INDEX idx_outbound_out_type ON outbound(out_type);
CREATE INDEX idx_outbound_material ON outbound(material);

-- 添加表注释（PostgreSQL方式）
COMMENT ON TABLE outbound IS '出库记录表';
COMMENT ON COLUMN outbound.outbound_order_id IS '出库记录唯一标识';
COMMENT ON COLUMN outbound.inventory_id IS '关联库存记录ID';
COMMENT ON COLUMN outbound.batch_no IS '批号，冗余存储便于查询';
COMMENT ON COLUMN outbound.material IS '材料类型';
COMMENT ON COLUMN outbound.specification IS '规格描述';
COMMENT ON COLUMN outbound.stock_weight IS '出库前库存重量';
COMMENT ON COLUMN outbound.out_weight IS '出库重量';
COMMENT ON COLUMN outbound.unit_price IS '单价';
COMMENT ON COLUMN outbound.total_amount IS '总金额';
COMMENT ON COLUMN outbound.out_type IS '出库类型：1-销售出库 2-调拨出库 3-退货出库';
COMMENT ON COLUMN outbound.out_date IS '出库日期';
COMMENT ON COLUMN outbound.vehicle_no IS '出库车牌号';
COMMENT ON COLUMN outbound.remark IS '出库备注';
COMMENT ON COLUMN outbound.created_at IS '创建时间';

-- =============================================
-- 3. 函数和触发器 - 自动更新库存状态（PostgreSQL方式）
-- =============================================

-- 创建更新库存状态的函数
CREATE OR REPLACE FUNCTION update_inventory_status()
RETURNS TRIGGER AS $$
BEGIN
    -- 更新库存状态为已出库
    UPDATE inventory 
    SET status = 2, 
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.inventory_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
CREATE TRIGGER after_outbound_insert
AFTER INSERT ON outbound
FOR EACH ROW
EXECUTE FUNCTION update_inventory_status();

-- =============================================
-- 4. 视图 - 库存状态统计
-- =============================================

-- 当前有效库存视图
CREATE VIEW current_inventory AS
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
CREATE VIEW outbound_summary AS
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
-- 5. 示例数据插入（用于测试）
-- =============================================

-- 插入库存示例数据
INSERT INTO inventory (
    batch_no, unit, specification, material, weight, 
    vehicle_no, transport_fee, advance_payment, storage_location, in_date, remark
) VALUES 
('HR20241220001', '吨', '2.0×1250×C', 'Q235B', 25.500, '京A12345', 1500.00, 50000.00, 'A区-01号库位', '2024-12-20', '首批入库'),
('HR20241220002', '吨', '3.0×1500×C', 'SPHC', 30.250, '京B67890', 1800.00, 60000.00, 'B区-02号库位', '2024-12-20', '优质产品'),
('HR20241220003', '吨', '1.5×1000×C', 'Q345B', 15.750, '京C54321', 1200.00, 30000.00, 'C区-03号库位', '2024-12-19', '特殊规格');

-- 插入出库示例数据
INSERT INTO outbound (
    inventory_id, batch_no, material, specification, stock_weight, out_weight,
    unit_price, total_amount, out_type, out_date, vehicle_no, remark
) VALUES 
(1, 'HR20241220001', 'Q235B', '2.0×1250×C', 25.500, 10.000, 4500.00, 45000.00, 1, '2024-12-20', '京D98765', '销售给客户A'),
(2, 'HR20241220002', 'SPHC', '3.0×1500×C', 30.250, 5.500, 4800.00, 26400.00, 2, '2024-12-20', '京E24680', '调拨到分公司');

-- =============================================
-- 6. 验证查询
-- =============================================

-- 查看当前库存
SELECT '当前库存统计' as info;
SELECT COUNT(*) as total_count, SUM(weight) as total_weight FROM current_inventory;

-- 查看出库记录
SELECT '出库记录统计' as info;
SELECT COUNT(*) as outbound_count, SUM(out_weight) as total_out_weight FROM outbound;

-- 查看库存状态分布
SELECT '库存状态分布' as info;
SELECT status, COUNT(*) as count FROM inventory GROUP BY status;
-- 为outbound表添加ref_no字段
ALTER TABLE outbound 
ADD COLUMN IF NOT EXISTS ref_no TEXT;

-- 为ref_no字段添加注释
COMMENT ON COLUMN outbound.ref_no IS '出库单号，格式：OUTYYYYMMDDXXX';

-- 可选：为ref_no字段添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_outbound_ref_no ON outbound(ref_no);