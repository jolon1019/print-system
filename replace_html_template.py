#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
替换main.html中的旧筛选系统为增强版筛选和统计系统
"""

import re
import os

def main():
    # 文件路径
    file_path = r'd:\print-system\hot-coil-print-system\main.html'
    backup_path = r'd:\print-system\hot-coil-print-system\main_backup_before_enhanced.html'

    print("📖 读取文件...")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    print(f"✅ 文件读取成功，总长度: {len(content)} 字符")

    # 创建备份
    print("📦 创建备份文件...")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ 备份已保存到: {backup_path}")

    # 定义要查找的模式（使用更宽松的正则表达式）
    old_pattern = re.compile(
        r'<!-- 时间段筛选按钮 -->.*?'
        r'<div class="stat-container" v-if="selectedTimeFilter">.*?</div>',
        re.DOTALL
    )

    # 新的增强版内容（完整的HTML）
    new_content = '''<!-- 增强版筛选面板 -->
                <div class="enhanced-filter-panel">
                    <el-collapse v-model="filterPanelExpanded">
                        <el-collapse-item name="filters">
                            <template #title>
                                <div class="filter-panel-header">
                                    <span class="filter-title">🔍 高级筛选</span>
                                    <el-tag v-if="activeFilterCount > 0" type="primary" size="small" class="filter-count-badge">
                                        {{ activeFilterCount }} 个条件已激活
                                    </el-tag>
                                </div>
                            </template>

                            <div class="filter-content">
                                <!-- 时间范围筛选 -->
                                <div class="filter-row">
                                    <div class="filter-group" style="grid-column: 1 / -1;">
                                        <label class="filter-label">⏰ 时间范围</label>
                                        <div class="time-filter-buttons">
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'today' }" @click="setTimeFilter('today')">今日</el-button>
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'yesterday' }" @click="setTimeFilter('yesterday')">昨日</el-button>
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'thisWeek' }" @click="setTimeFilter('thisWeek')">本周</el-button>
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'thisMonth' }" @click="setTimeFilter('thisMonth')">本月</el-button>
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'lastMonth' }" @click="setTimeFilter('lastMonth')">上月</el-button>
                                            <el-button class="time-filter-btn" :class="{ active: filterConditions.timeRange === 'custom' }" @click="setTimeFilter('custom')">自定义</el-button>
                                        </div>

                                        <div class="custom-date-range" v-if="filterConditions.timeRange === 'custom'">
                                            <el-date-picker
                                                v-model="filterConditions.customDateRange"
                                                type="daterange"
                                                range-separator="至"
                                                start-placeholder="开始日期"
                                                end-placeholder="结束日期"
                                                size="default"
                                                style="width: 100%;"
                                                @change="onFilterChange"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <!-- 出库类型 + 关键词搜索 -->
                                <div class="filter-row">
                                    <div class="filter-group">
                                        <label class="filter-label">📦 出库类型</label>
                                        <el-select v-model="filterConditions.outType" placeholder="全部类型" clearable style="width: 100%;" size="default" @change="onFilterChange">
                                            <el-option label="全部类型" :value="''" />
                                            <el-option v-for="opt in outTypeOptions" :key="opt.type_code" :label="opt.type_name" :value="opt.type_code" />
                                        </el-select>
                                    </div>

                                    <div class="filter-group">
                                        <label class="filter-label">🔎 关键词搜索</label>
                                        <el-input v-model="filterConditions.keyword" placeholder="输入车号/批号/出库单号..." clearable size="default" @input="debouncedFilterChange">
                                            <template #prefix><el-icon><Search /></el-icon></template>
                                        </el-input>
                                    </div>
                                </div>

                                <!-- 重量范围 + 金额范围 -->
                                <div class="filter-row">
                                    <div class="filter-group">
                                        <label class="filter-label">⚖️ 出库重量范围（吨）</label>
                                        <div class="range-inputs">
                                            <el-input-number v-model="filterConditions.minWeight" :min="0" :precision="3" :step="0.1" size="default" placeholder="最小值" controls-position="right" style="flex: 1;" @change="onFilterChange" />
                                            <span class="range-separator">至</span>
                                            <el-input-number v-model="filterConditions.maxWeight" :min="0" :precision="3" :step="0.1" size="default" placeholder="最大值" controls-position="right" style="flex: 1;" @change="onFilterChange" />
                                        </div>
                                    </div>

                                    <div class="filter-group">
                                        <label class="filter-label">💰 出库金额范围（元）</label>
                                        <div class="range-inputs">
                                            <el-input-number v-model="filterConditions.minAmount" :min="0" :step="1000" size="default" placeholder="最小值" controls-position="right" style="flex: 1;" @change="onFilterChange" />
                                            <span class="range-separator">至</span>
                                            <el-input-number v-model="filterConditions.maxAmount" :min="0" :step="1000" size="default" placeholder="最大值" controls-position="right" style="flex: 1;" @change="onFilterChange" />
                                        </div>
                                    </div>
                                </div>

                                <!-- 操作按钮 -->
                                <div class="filter-actions">
                                    <el-button type="primary" size="default" @click="applyFilters">🔍 应用筛选</el-button>
                                    <el-button size="default" @click="clearAllFilters">🗑️ 清除全部条件</el-button>
                                    <el-tag v-if="filteredOutboundRecords.length > 0" type="success" size="default" effect="dark">找到 {{ filteredOutboundRecords.length }} 条记录</el-tag>
                                </div>
                            </div>
                        </el-collapse-item>
                    </el-collapse>
                </div>

                <!-- 增强版统计卡片区域 -->
                <div class="enhanced-stats-container" v-if="filteredOutboundRecords.length > 0">
                    <div class="stat-card primary">
                        <div class="stat-card-icon">📊</div>
                        <div class="stat-card-label">筛选结果记录数</div>
                        <div class="stat-card-value">{{ enhancedStats.recordCount.toLocaleString() }}<span class="stat-card-unit">条</span></div>
                    </div>

                    <div class="stat-card success">
                        <div class="stat-card-icon">⚖️</div>
                        <div class="stat-card-label">总出库重量</div>
                        <div class="stat-card-value">{{ enhancedStats.totalWeight.toLocaleString() }}<span class="stat-card-unit">吨</span></div>
                    </div>

                    <div class="stat-card warning">
                        <div class="stat-card-icon">💰</div>
                        <div class="stat-card-label">总出库金额</div>
                        <div class="stat-card-value">¥{{ enhancedStats.totalAmount.toLocaleString() }}<span class="stat-card-unit">元</span></div>
                    </div>

                    <div class="stat-card info">
                        <div class="stat-card-icon">📈</div>
                        <div class="stat-card-label">平均每笔重量</div>
                        <div class="stat-card-value">{{ enhancedStats.avgWeight.toLocaleString() }}<span class="stat-card-unit">吨</span></div>
                    </div>

                    <div class="stat-card danger">
                        <div class="stat-card-icon">💵</div>
                        <div class="stat-card-label">平均每笔金额</div>
                        <div class="stat-card-value">¥{{ enhancedStats.avgAmount.toLocaleString() }}<span class="stat-card-unit">元</span></div>
                    </div>

                    <div class="stat-card primary">
                        <div class="stat-card-icon">🏆</div>
                        <div class="stat-card-label">最大单笔重量</div>
                        <div class="stat-card-value">{{ enhancedStats.maxWeight.toLocaleString() }}<span class="stat-card-unit">吨</span></div>
                    </div>
                </div>

                <!-- 分组统计表格（按出库类型） -->
                <div class="grouped-stats-section" v-if="statsGroupedByType.length > 0 && filteredOutboundRecords.length > 0">
                    <h3 style="margin: 20px 0 12px; font-size: 16px; color: #303133;">📋 按出库类型分组统计</h3>
                    <table class="grouped-stats-table">
                        <thead>
                            <tr>
                                <th>出库类型</th>
                                <th>记录数</th>
                                <th>总重量（吨）</th>
                                <th>总金额（元）</th>
                                <th>平均重量（吨）</th>
                                <th>占比</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="group in statsGroupedByType" :key="group.typeCode">
                                <td><el-tag :type="getOutTypeTagType(group.typeCode)" size="small">{{ group.typeName }}</el-tag></td>
                                <td><strong>{{ group.recordCount }}</strong></td>
                                <td>{{ group.totalWeight.toLocaleString() }}</td>
                                <td>¥{{ group.totalAmount.toLocaleString() }}</td>
                                <td>{{ (group.recordCount > 0 ? (group.totalWeight / group.recordCount) : 0).toFixed(3) }}</td>
                                <td>
                                    <el-progress :percentage="(group.recordCount / enhancedStats.recordCount * 100)" :stroke-width="10" :show-text="false" style="width: 120px;" />
                                    <span style="margin-left: 8px; font-size: 12px; color: #606266;">{{ (group.recordCount / enhancedStats.recordCount * 100).toFixed(1) }}%</span>
                                </td>
                            </tr>
                        </tbody>
                        <tfoot v-if="statsGroupedByType.length > 1">
                            <tr style="background: #f5f7fa; font-weight: bold;">
                                <td>合计</td>
                                <td>{{ enhancedStats.recordCount }}</td>
                                <td>{{ enhancedStats.totalWeight.toLocaleString() }}</td>
                                <td>¥{{ enhancedStats.totalAmount.toLocaleString() }}</td>
                                <td>{{ enhancedStats.avgWeight.toFixed(3) }}</td>
                                <td>100%</td>
                            </tr>
                        </tfoot>
                    </table>
                </div>'''

    # 执行替换
    print("🔧 执行替换操作...")
    new_file_content, count = old_pattern.subn(new_content, content)

    if count == 0:
        print("❌ 错误：未找到要替换的内容")
        print("\n调试信息：")
        print("尝试搜索关键标记...")

        # 搜索一些关键标记来帮助定位问题
        markers = [
            '<!-- 时间段筛选按钮 -->',
            'selectedTimeFilter',
            'filteredOutboundStats',
            'filterByTime',
        ]

        for marker in markers:
            pos = content.find(marker)
            if pos != -1:
                lines_before = content[:pos].count('\n')
                print(f"✅ 找到 '{marker}' 在第 {lines_before + 1} 行，位置 {pos}")
            else:
                print(f"❌ 未找到 '{marker}'")

        return False
    else:
        print(f"✅ 成功替换 {count} 处内容")

    # 写入文件
    print("💾 写入文件...")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_file_content)

    print("✅ 文件更新成功！")
    print(f"\n📊 统计信息:")
    print(f"   原始文件大小: {os.path.getsize(backup_path):,} 字节")
    print(f"   更新后大小: {os.path.getsize(file_path):,} 字节")
    print(f"\n✨ 增强版筛选和统计系统的HTML模板已成功集成！")
    print(f"\n下一步：需要继续集成JavaScript代码部分")

    return True

if __name__ == '__main__':
    try:
        success = main()
        exit(0 if success else 1)
    except Exception as e:
        print(f"❌ 发生错误: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
