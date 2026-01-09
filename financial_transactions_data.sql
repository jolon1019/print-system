-- =============================================
-- 财务交易数据表示例数据
-- =============================================

-- =============================================
-- 1. 插入交易分类数据
-- =============================================

-- 收入分类
INSERT INTO transaction_categories (category_name, category_type, description, sort_order) VALUES
('工资收入', 1, '工资、奖金等劳动报酬', 1),
('投资收入', 1, '股票、基金等投资收益', 2),
('租金收入', 1, '房屋、设备等租金收入', 3),
('销售收入', 1, '商品销售、服务收入', 4),
('其他收入', 1, '其他各类收入', 5);

-- 支出分类
INSERT INTO transaction_categories (category_name, category_type, parent_id, description, sort_order) VALUES
-- 生活支出
('食品饮料', 2, NULL, '日常食品、饮料支出', 1),
('餐饮外卖', 2, NULL, '餐厅用餐、外卖支出', 2),
('交通出行', 2, NULL, '公共交通、打车、加油等', 3),
('住房相关', 2, NULL, '房租、水电、物业等', 4),
('通讯网络', 2, NULL, '手机费、宽带费等', 5),

-- 娱乐休闲
('娱乐活动', 2, NULL, '电影、游戏、旅游等', 6),
('购物消费', 2, NULL, '服装、电子产品等购物', 7),

-- 健康医疗
('医疗保健', 2, NULL, '看病、买药、体检等', 8),

-- 教育培训
('教育培训', 2, NULL, '学费、培训费等', 9),

-- 其他支出
('其他支出', 2, NULL, '其他各类支出', 10);

-- =============================================
-- 2. 插入财务交易示例数据
-- =============================================

-- 收入交易示例
INSERT INTO financial_transactions (
    transaction_date, transaction_type, income_amount, description, 
    category_id, payment_method, reference_no, status
) VALUES
('2024-12-01', 1, 15000.00, '12月工资收入', 1, 2, 'SAL20241201', 1),
('2024-12-05', 1, 2500.00, '股票分红收入', 2, 2, 'INV20241205', 1),
('2024-12-10', 1, 3000.00, '项目奖金', 1, 2, 'BNS20241210', 1),
('2024-12-15', 1, 1800.00, '兼职收入', 1, 3, 'PT20241215', 1),
('2024-12-20', 1, 1200.00, '租金收入', 3, 2, 'RENT20241220', 1);

-- 支出交易示例
INSERT INTO financial_transactions (
    transaction_date, transaction_type, expense_amount, description, 
    category_id, payment_method, reference_no, status, notes
) VALUES
-- 食品饮料支出
('2024-12-02', 2, 350.00, '超市购物', 6, 3, 'EXP2024120201', 1, '购买一周食材'),
('2024-12-05', 2, 85.00, '水果采购', 6, 3, 'EXP2024120501', 1, '新鲜水果'),

-- 餐饮外卖支出
('2024-12-03', 2, 45.00, '午餐外卖', 7, 4, 'EXP2024120301', 1, '工作日午餐'),
('2024-12-08', 2, 120.00, '家庭聚餐', 7, 2, 'EXP2024120801', 1, '周末家庭聚餐'),

-- 交通出行支出
('2024-12-04', 2, 200.00, '加油费', 8, 2, 'EXP2024120401', 1, '汽车加油'),
('2024-12-07', 2, 60.00, '地铁卡充值', 8, 3, 'EXP2024120701', 1, '公共交通'),

-- 住房相关支出
('2024-12-01', 2, 3500.00, '房租', 9, 2, 'EXP2024120101', 1, '12月房租'),
('2024-12-10', 2, 280.00, '水电费', 9, 3, 'EXP2024121001', 1, '水电煤气费'),

-- 通讯网络支出
('2024-12-05', 2, 98.00, '手机话费', 10, 4, 'EXP2024120502', 1, '月度套餐费'),

-- 娱乐休闲支出
('2024-12-06', 2, 75.00, '电影票', 11, 3, 'EXP2024120601', 1, '周末观影'),
('2024-12-12', 2, 200.00, '购物消费', 12, 2, 'EXP2024121201', 1, '服装购买'),

-- 医疗保健支出
('2024-12-09', 2, 150.00, '药品购买', 13, 3, 'EXP2024120901', 1, '日常药品'),

-- 教育培训支出
('2024-12-15', 2, 800.00, '在线课程', 14, 2, 'EXP2024121501', 1, '技能提升课程');

-- 转账交易示例
INSERT INTO financial_transactions (
    transaction_date, transaction_type, income_amount, expense_amount, description, 
    payment_method, reference_no, status, notes
) VALUES
('2024-12-18', 3, 0.00, 1000.00, '转账给家人', 2, 'TRF2024121801', 1, '家庭支持'),
('2024-12-22', 3, 500.00, 0.00, '收到朋友转账', 3, 'TRF2024122201', 1, '借款归还');

-- =============================================
-- 3. 验证数据插入结果
-- =============================================

-- 查看交易统计
SELECT '交易数据统计' as info;
SELECT 
    COUNT(*) as total_transactions,
    SUM(income_amount) as total_income,
    SUM(expense_amount) as total_expense,
    SUM(net_amount) as net_balance
FROM financial_transactions
WHERE status = 1;

-- 查看分类统计
SELECT '分类统计' as info;
SELECT 
    c.category_name,
    c.category_type,
    COUNT(*) as transaction_count,
    SUM(t.income_amount) as total_income,
    SUM(t.expense_amount) as total_expense
FROM financial_transactions t
LEFT JOIN transaction_categories c ON t.category_id = c.category_id
WHERE t.status = 1
GROUP BY c.category_id, c.category_name, c.category_type
ORDER BY c.category_type, total_income DESC, total_expense DESC;

-- 查看月度统计
SELECT '月度统计' as info;
SELECT 
    TO_CHAR(transaction_date, 'YYYY-MM') as month,
    COUNT(*) as transactions,
    SUM(income_amount) as income,
    SUM(expense_amount) as expense,
    SUM(net_amount) as balance
FROM financial_transactions
WHERE status = 1
GROUP BY TO_CHAR(transaction_date, 'YYYY-MM')
ORDER BY month DESC;