-- =============================================
-- 快速绑定用户单位 - 直接执行即可
-- =============================================

-- 步骤 1：先查看当前所有用户
SELECT id, username, real_name, role FROM public.users ORDER BY id;

-- 步骤 2：查看可用的单位
SELECT DISTINCT unit, COUNT(*) as count 
FROM public.inventory 
WHERE is_listed = true 
GROUP BY unit 
ORDER BY unit;

-- =============================================
-- 步骤 3：为用户绑定单位（根据实际情况修改）
-- =============================================

-- 示例 1：为用户 ID = 1 绑定单位A
INSERT INTO public.user_units (user_id, unit)
VALUES (1, '单位A')
ON CONFLICT (user_id, unit) DO NOTHING;

-- 示例 2：为用户 ID = 1 绑定多个单位
INSERT INTO public.user_units (user_id, unit)
VALUES 
    (1, '单位A'),
    (1, '单位B'),
    (1, '单位C')
ON CONFLICT (user_id, unit) DO NOTHING;

-- 示例 3：为用户绑定单位
-- 注意：请根据实际用户 ID 修改
INSERT INTO public.user_units (user_id, unit)
VALUES (1, '单位A')
ON CONFLICT (user_id, unit) DO NOTHING;

-- =============================================
-- 验证：查看所有用户的单位绑定情况
-- =============================================

SELECT 
    u.id,
    u.username,
    u.real_name,
    u.role,
    STRING_AGG(uu.unit, ', ' ORDER BY uu.unit) as units,
    COUNT(uu.unit) as unit_count
FROM public.users u
LEFT JOIN public.user_units uu ON u.id = uu.user_id
GROUP BY u.id, u.username, u.real_name, u.role
ORDER BY u.id;
