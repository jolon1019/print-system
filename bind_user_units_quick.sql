-- =============================================
-- 为用户绑定单位 - 快速操作脚本
-- 使用说明：
-- 1. 修改下方的 1 为目标用户的 ID
-- 2. 修改 '单位A' 为要绑定的单位名称
-- 3. 在 Supabase SQL 编辑器中执行
-- =============================================

-- 方法一：为单个用户绑定单个单位
-- =============================================

-- 替换下面的实际值
-- 1  -- 用户 ID（从 users 表查询）
-- '单位A'  -- 要绑定的单位名称

INSERT INTO public.user_units (user_id, unit)
VALUES (1, '单位A')
ON CONFLICT (user_id, unit) DO NOTHING;

-- 方法二：为单个用户绑定多个单位
-- =============================================

-- 替换下面的实际值
-- 1  -- 用户 ID
-- ARRAY['单位A', '单位B']  -- 单位名称数组

INSERT INTO public.user_units (user_id, unit)
SELECT 1, unnest(ARRAY['单位A', '单位B'])
ON CONFLICT (user_id, unit) DO NOTHING;

-- 方法三：批量为多个用户绑定单位
-- =============================================

-- 示例：为 user1 绑定单位A和单位B
INSERT INTO public.user_units (user_id, unit)
SELECT 1, '单位A'
UNION ALL
SELECT 1, '单位B'
ON CONFLICT (user_id, unit) DO NOTHING;

-- 示例：为用户绑定单位
-- 注意：请根据实际用户 ID 修改
INSERT INTO public.user_units (user_id, unit)
SELECT 1, '单位C'
ON CONFLICT (user_id, unit) DO NOTHING;

-- =============================================
-- 查询验证 - 查看所有用户的单位绑定
-- =============================================

SELECT 
    u.id as user_id,
    u.username,
    u.real_name,
    STRING_AGG(uu.unit, ', ' ORDER BY uu.unit) as units,
    COUNT(uu.unit) as unit_count
FROM public.users u
LEFT JOIN public.user_units uu ON u.id = uu.user_id
WHERE u.status = 1
GROUP BY u.id, u.username, u.real_name
ORDER BY u.username;

-- =============================================
-- 查询验证 - 查看特定用户的单位绑定
-- =============================================

-- 替换 'user1' 为要查询的用户名
SELECT 
    u.id as user_id,
    u.username,
    u.real_name,
    STRING_AGG(uu.unit, ', ' ORDER BY uu.unit) as units
FROM public.users u
LEFT JOIN public.user_units uu ON u.id = uu.user_id
WHERE u.username = 'user1'
GROUP BY u.id, u.username, u.real_name;

-- =============================================
-- 删除单位绑定
-- =============================================

-- 删除用户的所有单位绑定
-- DELETE FROM public.user_units WHERE user_id = 1;

-- 删除用户的特定单位绑定
-- DELETE FROM public.user_units WHERE user_id = 1 AND unit = '单位A';

-- =============================================
-- 常用操作示例
-- =============================================

-- 查看所有可用的单位（从 inventory 表）
SELECT DISTINCT unit, COUNT(*) as count
FROM public.inventory
WHERE is_listed = true
GROUP BY unit
ORDER BY unit;
