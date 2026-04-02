-- =============================================
-- 查询 inventory 表中所有单位
-- 用于了解实际存在的单位名称
-- =============================================

SELECT DISTINCT unit, COUNT(*) as count
FROM public.inventory
WHERE is_listed = true
GROUP BY unit
ORDER BY unit;
