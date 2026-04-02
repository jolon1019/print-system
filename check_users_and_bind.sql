-- =============================================
-- 查看当前用户列表 - 修复外键约束错误
-- =============================================

-- 查看所有用户
SELECT id, username, real_name, role, status 
FROM public.users 
ORDER BY id;

-- 查看用户数量
SELECT COUNT(*) as user_count 
FROM public.users 
WHERE status = 1;

-- =============================================
-- 查看可用的单位
-- =============================================

SELECT DISTINCT unit, COUNT(*) as count 
FROM public.inventory 
WHERE is_listed = true 
GROUP BY unit 
ORDER BY unit;

-- =============================================
-- 为实际存在的用户绑定单位
-- 注意：请根据上面查询结果修改用户 ID
-- =============================================

-- 示例：为第一个用户（ID = 1）绑定单位
INSERT INTO public.user_units (user_id, unit)
VALUES (1, '单位A')
ON CONFLICT (user_id, unit) DO NOTHING;

-- 示例：为第一个用户绑定多个单位
INSERT INTO public.user_units (user_id, unit)
VALUES 
    (1, '单位A'),
    (1, '单位B')
ON CONFLICT (user_id, unit) DO NOTHING;

-- =============================================
-- 验证绑定结果
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
