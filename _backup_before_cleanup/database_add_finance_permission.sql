-- =====================================================
-- 添加财务权限字段到用户表
-- =====================================================

-- 添加 can_view_finance 字段到 users 表
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS can_view_finance BOOLEAN NOT NULL DEFAULT FALSE;

-- 添加字段注释
COMMENT ON COLUMN public.users.can_view_finance IS '财务查看权限：true-可查看，false-不可查看';

-- 为管理员用户默认开启财务权限
UPDATE public.users 
SET can_view_finance = true 
WHERE role = 'admin';

-- =====================================================
-- 完成
-- =====================================================
