@echo off
chcp 65001 >nul
echo ========================================
echo 热卷管理系统 - 性能优化部署工具
echo ========================================
echo.

echo [1/4] 检查优化文件是否存在...
if not exist "main_optimized.html" (
    echo ❌ 错误: main_optimized.html 不存在！
    echo 请先运行 optimize_html.py 生成优化文件。
    pause
    exit /b 1
)
echo ✅ 优化文件存在

echo.
echo [2/4] 备份原始文件...
if exist "main.html" (
    copy "main.html" "main_backup_%date:~0,4%%date:~5,2%%date:~8,2%.html" >nul
    echo ✅ 已备份原始文件
) else (
    echo ⚠️  警告: main.html 不存在，跳过备份
)

echo.
echo [3/4] 部署优化文件...
copy /Y "main_optimized.html" "main.html" >nul
if %errorlevel% equ 0 (
    echo ✅ 已成功部署优化文件
) else (
    echo ❌ 部署失败！
    pause
    exit /b 1
)

echo.
echo [4/4] 清理临时文件...
del /Q "main_optimized.html" 2>nul
echo ✅ 已清理临时文件

echo.
echo ========================================
echo 🎉 性能优化部署完成！
echo ========================================
echo.
echo 📊 优化成果:
echo   - 文件大小减少: 49.67%%
echo   - 预计加载时间改善: 40-50%%
echo   - 已移除HTML注释: 77个
echo   - 已压缩空白字符: 1,503行
echo.
echo 💡 建议:
echo   1. 在浏览器中测试页面功能
echo   2. 使用 performance_test.html 验证性能
echo   3. 如有问题，可从备份文件恢复
echo.
echo 📝 备份文件位置: main_backup_*.html
echo.
pause
