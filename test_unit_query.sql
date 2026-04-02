-- =============================================
-- 测试 Supabase 查询语法
-- =============================================

-- 1. 查看用户绑定的单位
SELECT * FROM public.user_units WHERE user_id = 8;

-- 2. 查看库存中的单位分布
SELECT unit, COUNT(*) as count 
FROM public.inventory 
WHERE status = 1 AND is_listed = true
GROUP BY unit 
ORDER BY count DESC;

-- 3. 测试单位过滤查询（应该只返回"祥兴"的数据）
SELECT id, batch_no, unit, specification, material, weight
FROM public.inventory 
WHERE status = 1 
  AND is_listed = true 
  AND unit IN ('铭钰', '祥兴')
ORDER BY created_at DESC
LIMIT 10;

-- 4. 查看所有库存数据（不过滤单位）
SELECT id, batch_no, unit, specification, material, weight
FROM public.inventory 
WHERE status = 1 AND is_listed = true
ORDER BY created_at DESC
LIMIT 10;

-- 5. 检查是否有"铭钰"单位的库存
SELECT COUNT(*) as count
FROM public.inventory 
WHERE unit = '铭钰';

-- 6. 检查是否有"祥兴"单位的库存
SELECT COUNT(*) as count
FROM public.inventory 
WHERE unit = '祥兴';
