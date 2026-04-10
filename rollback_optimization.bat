@echo off
chcp 65001 >nul
echo ========================================
echo 热卷管理系统 - 性能优化回滚工具
echo ========================================
echo.

echo [1/3] 查找备份文件...
set "backup_file="
for /f "delims=" %%f in ('dir /b /o-d main_backup_*.html 2^>nul') do (
    if not defined backup_file set "backup_file=%%f"
)

if not defined backup_file (
    echo ❌ 错误: 未找到备份文件！
    echo 备份文件格式: main_backup_YYYYMMDD.html
    pause
    exit /b 1
)

echo ✅ 找到备份文件: %backup_file%

echo.
echo [2/3] 恢复原始文件...
copy /Y "%backup_file%" "main.html" >nul
if %errorlevel% equ 0 (
    echo ✅ 已成功恢复原始文件
) else (
    echo ❌ 恢复失败！
    pause
    exit /b 1
)

echo.
echo [3/3] 保留备份文件...
echo ✅ 备份文件已保留: %backup_file%

echo.
echo ========================================
echo 🔄 性能优化已回滚
echo ========================================
echo.
echo 📝 说明:
echo   - 已恢复到优化前的版本
echo   - 备份文件已保留，可手动删除
echo   - 如需重新优化，请运行 optimize_html.py
echo.
pause
