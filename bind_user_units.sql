-- =============================================
-- 为测试用户绑定单位
-- 执行此脚本后，测试用户将可以查看对应单位的数据
-- =============================================

-- 为 user1 (张三) 绑定单位
INSERT INTO public.user_units (user_id, unit)
SELECT id, '单位A' FROM public.users WHERE username = 'user1'
ON CONFLICT (user_id, unit) DO NOTHING;

INSERT INTO public.user_units (user_id, unit)
SELECT id, '单位B' FROM public.users WHERE username = 'user1'
ON CONFLICT (user_id, unit) DO NOTHING;

-- 为 user2 (李四) 绑定单位
INSERT INTO public.user_units (user_id, unit)
SELECT id, '单位C' FROM public.users WHERE username = 'user2'
ON CONFLICT (user_id, unit) DO NOTHING;

-- 查询验证
SELECT 
    u.username,
    u.real_name,
    STRING_AGG(uu.unit, ', ') as units
FROM public.users u
LEFT JOIN public.user_units uu ON u.id = uu.user_id
WHERE u.role = 'user'
GROUP BY u.id, u.username, u.real_name
ORDER BY u.username;
