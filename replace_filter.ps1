# PowerShell脚本 - 替换main.html中的旧筛选代码为新的增强版代码

$filePath = "d:\print-system\hot-coil-print-system\main.html"
$backupPath = "d:\print-system\hot-coil-print-system\main_backup_before_enhanced_filter.html"

# 创建备份
Write-Host "📦 创建备份文件..."
Copy-Item $filePath $backupPath -Force

# 读取文件内容
Write-Host "📖 读取文件内容..."
$content = Get-Content $filePath -Raw -Encoding UTF8

# 定义旧内容的开始和结束标记
$startMarker = "<!-- 时间段筛选按钮 -->"
$endMarker = "</div>"  # stat-container的结束标签

# 找到开始位置
$startIndex = $content.IndexOf($startMarker)
if ($startIndex -eq -1) {
    Write-Host "❌ 错误：找不到开始标记 '$startMarker'" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 找到开始标记，位置: $startIndex"

# 从开始位置往后找到stat-container的结束</div>（需要找到正确的结束位置）
# 我们需要找到第5232行的</div>
$searchContent = $content.Substring($startIndex)

# 找到stat-container及其结束标签
$statContainerStart = $searchContent.IndexOf('<div class="stat-container"')
if ($statContainerStart -eq -1) {
    Write-Host "❌ 错误：找不到 stat-container" -ForegroundColor Red
    exit 1
}

# 从stat-container开始找对应的结束</div>
$afterStatContainer = $searchContent.Substring($statContainerStart)
# 简单方法：找到stat-container后的第一个完整</div>（包含换行）
$endDivIndex = $afterStatContainer.IndexOf("</div>" + "`r`n`r`n" + "`r`n" + "                </div>")
if ($endDivIndex -eq -1) {
    # 尝试另一种模式
    $endDivIndex = $afterStatContainer.IndexOf("</div>" + "`n" + "`n" + "                </div>")
}

if ($endDivIndex -eq -1) {
    Write-Host "⚠️ 使用备用方法定位结束位置..."

    # 备用方法：直接计算从startIndex到大约5232行的距离
    # 根据之前的分析，我们需要替换的内容大约是从5176行到5232行
    $lines = ($content.Substring(0, $startIndex) -split "`n").Count
    Write-Host "   开始标记在第 $lines 行"

    # 读取该区域的内容用于调试
    $sampleContent = $content.Substring($startIndex, [Math]::Min(3000, $content.Length - $startIndex))
    $sampleLines = $sampleContent -split "`n"

    Write-Host "   接下来的前20行内容:"
    for ($i = 0; $i -lt [Math]::Min(20, $sampleLines.Count); $i++) {
        Write-Host "   $($i+1): $($sampleLines[$i].Trim())"
    }
} else {
    $totalEndIndex = $startIndex + $statContainerStart + $endDivIndex + 6  # 6是"</div>"的长度
    Write-Host "✅ 找到结束位置: $totalEndIndex"

    # 提取要替换的旧内容
    $oldContent = $content.Substring($startIndex, $totalEndIndex - $startIndex)
    Write-Host "📝 将要替换的内容长度: $($oldContent.Length) 字符"
}
