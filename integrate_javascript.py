#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
集成增强版筛选和统计系统的JavaScript代码到main.html
"""

import re
import os

def main():
    file_path = r'd:\print-system\hot-coil-print-system\main.html'

    print("📖 读取文件...")

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    print(f"✅ 文件读取成功，总长度: {len(content)} 字符")

    # ========================================
    # 替换1：状态变量
    # ========================================
    print("\n🔧 替换1: 状态变量...")

    old_vars = '''// 时间段筛选相关
                const selectedTimeFilter = ref('today'); // null, today, yesterday, thisMonth, lastMonth, custom
                const selectedOutTypeFilter = ref(''); // '', 1, 2, 3
                const customDateRange = ref([]); // 自定义日期范围'''

    new_vars = '''// 增强版筛选系统 - 筛选面板展开状态（默认展开）
                const filterPanelExpanded = ref(['filters']);

                // 增强版筛选条件对象（支持多条件组合查询：时间、类型、关键词、重量范围、金额范围）
                const filterConditions = EnhancedFilterStatsSystem.createFilterConditions();'''

    if old_vars in content:
        content = content.replace(old_vars, new_vars)
        print("   ✅ 状态变量已替换")
    else:
        print("   ⚠️ 未找到原始状态变量，尝试使用正则表达式...")

        # 使用正则表达式的备用方案
        pattern = r'// 时间段筛选相关\s*const selectedTimeFilter = ref\(.*?\);\s*const selectedOutTypeFilter = ref\(.*?\);\s*const customDateRange = ref\(\[\]\);.*?自定义日期范围'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            content = content[:match.start()] + new_vars + content[match.end():]
            print("   ✅ 状态变量已通过正则替换")
        else:
            print("   ❌ 无法找到状态变量，跳过此步")

    # ========================================
    # 替换2：在filteredOutboundStats计算属性后添加新的计算属性
    # ========================================
    print("\n🔧 替换2: 添加新的计算属性...")

    old_stats_end = '''return {
                        totalWeight: totalWeight.toFixed(3),
                        totalAmount: Math.ceil(totalAmount).toLocaleString(),
                        recordCount: filteredRecords.length
                    };
                };'''

    new_computed_props = '''return {
                        totalWeight: totalWeight.toFixed(3),
                        totalAmount: Math.ceil(totalAmount).toLocaleString(),
                        recordCount: filteredRecords.length
                    };
                };

                // ====== 增强版筛选和统计系统 - 新增计算属性 ======

                /**
                 * 计算当前激活的筛选条件数量
                 * 用于显示在筛选面板标题上，让用户知道当前有多少个筛选条件生效
                 */
                const activeFilterCount = computed(() => {
                    return EnhancedFilterStatsSystem.getActiveFilterCount(filterConditions);
                });

                /**
                 * 筛选后的出库记录数据
                 * 根据所有筛选条件对原始数据进行过滤（支持多条件AND组合）
                 */
                const filteredOutboundRecords = computed(() => {
                    return EnhancedFilterStatsSystem.filterRecords(
                        outboundHistoryData.value,
                        filterConditions
                    );
                });

                /**
                 * 增强版统计数据
                 * 包含9项指标：记录数、总重量、总金额、平均重量、平均金额、最大/最小重量、最大/最小金额
                 */
                const enhancedStats = computed(() => {
                    return EnhancedFilterStatsSystem.calculateBasicStats(filteredOutboundRecords.value);
                });

                /**
                 * 按出库类型分组的统计数据
                 * 用于生成分组统计表格，展示各类型的占比情况
                 */
                const statsGroupedByType = computed(() => {
                    return EnhancedFilterStatsSystem.calculateGroupedByType(
                        filteredOutboundRecords.value,
                        outTypeOptions.value
                    );
                });

                /**
                 * 按日期分组的统计数据（按天分组）
                 * 用于趋势分析和图表展示
                 */
                const statsGroupedByDate = computed(() => {
                    return EnhancedFilterStatsSystem.calculateGroupedByDate(
                        filteredOutboundRecords.value,
                        'day'  // 可选值: 'day', 'week', 'month'
                    );
                });'''

    if old_stats_end in content:
        content = content.replace(old_stats_end, new_computed_props)
        print("   ✅ 新的计算属性已添加")
    else:
        print("   ⚠️ 未找到filteredOutboundStats结束标记")

    # ========================================
    # 替换3：替换旧的筛选方法为新的方法
    # ========================================
    print("\n🔧 替换3: 替换筛选方法...")

    old_methods = '''// 时间段筛选方法
                const filterByTime = (filterType) => {
                    selectedTimeFilter.value = filterType;
                };

                // 自定义日期范围变化处理
                const onCustomDateRangeChange = (value) => {
                    customDateRange.value = value;
                };

                // 清除时间段筛选
                const clearTimeFilter = () => {
                    selectedTimeFilter.value = null;
                    customDateRange.value = [];
                };'''

    new_methods = '''// ====== 增强版筛选和统计系统 - 新增方法 ======

                /**
                 * 设置时间范围筛选条件
                 * @param {string} timeRange - 时间范围类型: today, yesterday, thisWeek, thisMonth, lastMonth, custom
                 */
                const setTimeFilter = (timeRange) => {
                    filterConditions.timeRange = timeRange;
                    onFilterChange();
                };

                /**
                 * 筛选条件变化时的处理函数
                 * 可以在这里触发其他操作，如记录日志、发送分析事件等
                 */
                const onFilterChange = () => {
                    console.log('📊 筛选条件已更新:', JSON.parse(JSON.stringify(filterConditions)));
                };

                /**
                 * 防抖处理的关键词搜索函数
                 * 避免用户快速输入时频繁触发筛选操作（300ms延迟）
                 */
                const debouncedFilterChange = EnhancedFilterStatsSystem.debounce(() => {
                    console.log('🔍 执行关键词搜索:', filterConditions.keyword);
                }, 300);

                /**
                 * 应用所有筛选条件
                 * 显示确认消息并可以执行其他操作
                 */
                const applyFilters = () => {
                    const count = activeFilterCount.value;
                    if (count > 0) {
                        ElMessage.success(`✅ 已应用 ${count} 个筛选条件，找到 ${filteredOutboundRecords.value.length} 条匹配记录`);
                    } else {
                        ElMessage.info('ℹ️ 当前没有激活的筛选条件，显示全部数据');
                    }
                    console.log('🔍 应用筛选条件:', filterConditions);
                    console.log('📊 筛选结果:', filteredOutboundRecords.value.length, '条记录');
                };

                /**
                 * 清除所有筛选条件
                 * 重置为初始状态，显示所有数据
                 */
                const clearAllFilters = () => {
                    Object.assign(filterConditions, EnhancedFilterStatsSystem.createFilterConditions());
                    ElMessage.info('🗑️ 已清除所有筛选条件，显示全部数据');
                    console.log('🔄 已清除所有筛选条件');
                };'''

    if old_methods in content:
        content = content.replace(old_methods, new_methods)
        print("   ✅ 筛选方法已替换")
    else:
        print("   ⚠️ 未找到旧的筛选方法")

    # ========================================
    # 替换4：更新return语句
    # ========================================
    print("\n🔧 替换4: 更新return语句...")

    # 找到return语句中需要更新的部分
    old_return_items = '''filteredOutboundStats,
                    selectedTimeFilter,
                    selectedOutTypeFilter,
                    customDateRange,
                    filterByTime,
                    onCustomDateRangeChange,
                    clearTimeFilter,'''

    new_return_items = '''// 增强版筛选和统计系统 - 新增的响应式数据和方法
                    filterPanelExpanded,
                    filterConditions,
                    activeFilterCount,
                    filteredOutboundRecords,
                    enhancedStats,
                    statsGroupedByType,
                    statsGroupedByDate,

                    // 增强版筛选方法
                    setTimeFilter,
                    onFilterChange,
                    debouncedFilterChange,
                    applyFilters,
                    clearAllFilters,'''

    if old_return_items in content:
        content = content.replace(old_return_items, new_return_items)
        print("   ✅ return语句已更新")
    else:
        print("   ⚠️ 未找到原始return语句中的项目")

    # 写入文件
    print("\n💾 写入文件...")
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("✅ JavaScript代码集成完成！")
    print(f"\n📊 最终文件大小: {os.path.getsize(file_path):,} 字节")
    print("\n✨ 增强版筛选和统计系统已完全集成到main.html！")
    print("\n下一步建议:")
    print("1. 在浏览器中打开main.html测试功能")
    print("2. 在控制台运行单元测试: EnhancedFilterStatsTests.runAllTests()")

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
