/**
 * 增强版筛选和统计系统 - JavaScript集成代码
 *
 * 使用方法：
 * 1. 将以下代码添加到main.html的 <script setup> 部分
 * 2. 替换原有的筛选相关状态变量、计算属性和方法
 */

// ============================================================
// 第一部分：替换原有的状态变量（约第6139-6141行）
// ============================================================

// ❌ 删除以下旧代码：
// const selectedTimeFilter = ref('today');
// const selectedOutTypeFilter = ref('');
// const customDateRange = ref([]);

// ✅ 添加以下新代码：

// 筛选面板展开状态（默认展开）
const filterPanelExpanded = ref(['filters']);

// 增强版筛选条件对象（支持多条件组合查询）
const filterConditions = EnhancedFilterStatsSystem.createFilterConditions();


// ============================================================
// 第二部分：添加新的计算属性（在原有计算属性区域）
// ============================================================

/**
 * 计算当前激活的筛选条件数量
 * 用于显示在筛选面板标题上，让用户知道当前有多少个筛选条件生效
 */
const activeFilterCount = computed(() => {
    return EnhancedFilterStatsSystem.getActiveFilterCount(filterConditions);
});

/**
 * 筛选后的出库记录数据
 * 根据所有筛选条件对原始数据进行过滤
 */
const filteredOutboundRecords = computed(() => {
    return EnhancedFilterStatsSystem.filterRecords(
        outboundHistoryData.value,
        filterConditions
    );
});

/**
 * 增强版统计数据
 * 包含基础统计指标：记录数、总重量、总金额、平均值、最大/最小值等
 */
const enhancedStats = computed(() => {
    return EnhancedFilterStatsSystem.calculateBasicStats(filteredOutboundRecords.value);
});

/**
 * 按出库类型分组的统计数据
 * 用于生成分组统计表格
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
        'day'  // 可选: 'day', 'week', 'month'
    );
});


// ============================================================
// 第三部分：添加新的交互方法（在原有方法区域）
// ============================================================

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

    // 可选：保存筛选条件到localStorage实现持久化
    // localStorage.setItem('outbound_filter_conditions', JSON.stringify(filterConditions));
};

/**
 * 防抖处理的关键词搜索函数
 * 避免用户快速输入时频繁触发筛选操作
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

    // 可以在这里添加其他逻辑，例如：
    // - 发送筛选分析事件到后端
    // - 记录用户筛选习惯
    // - 触发数据导出预览等
};

/**
 * 清除所有筛选条件
 * 重置为初始状态，显示所有数据
 */
const clearAllFilters = () => {
    // 使用Object.assign重置所有字段到初始值
    Object.assign(filterConditions, EnhancedFilterStatsSystem.createFilterConditions());

    ElMessage.info('🗑️ 已清除所有筛选条件，显示全部数据');
    console.log('🔄 已清除所有筛选条件');

    // 清除localStorage中的缓存（如果之前保存过）
    // localStorage.removeItem('outbound_filter_conditions');
};


// ============================================================
// 第四部分：更新return语句（约第12126-12142行）
// ============================================================

// 在setup()函数的return语句中添加以下内容：

return {
    // ... 保留已有的变量和方法 ...

    // ===== 新增的筛选和统计相关响应式数据 =====
    filterPanelExpanded,
    filterConditions,

    // 新增的计算属性
    activeFilterCount,
    filteredOutboundRecords,      // 替代原来的过滤逻辑
    enhancedStats,                // 替代原来的 filteredOutboundStats
    statsGroupedByType,           // 新增：按类型分组的统计
    statsGroupedByDate,           // 新增：按日期分组的统计

    // 新增的方法
    setTimeFilter,                // 替代原来的 filterByTime
    onFilterChange,               // 替代原来的 onCustomDateRangeChange
    debouncedFilterChange,        // 新增：防抖搜索
    applyFilters,                 // 新增：应用筛选按钮
    clearAllFilters,              // 替代原来的 clearTimeFilter

    // ===== 可以选择保留或删除的旧代码（向后兼容） =====

    // 如果需要保持向后兼容，可以保留以下别名：
    /*
    selectedTimeFilter: computed({
        get: () => filterConditions.timeRange,
        set: (val) => { filterConditions.timeRange = val; }
    }),
    selectedOutTypeFilter: computed({
        get: () => filterConditions.outType,
        set: (val) => { filterConditions.outType = val; }
    }),
    customDateRange: computed({
        get: () => filterConditions.customDateRange,
        set: (val) => { filterConditions.customDateRange = val; }
    }),
    filteredOutboundStats: computed(() => ({
        recordCount: enhancedStats.value.recordCount,
        totalWeight: enhancedStats.value.totalWeight.toFixed(3),
        totalAmount: enhancedStats.value.totalAmount.toLocaleString()
    })),
    filterByTime: setTimeFilter,
    clearTimeFilter: clearAllFilters,
    onCustomDateRangeChange: onFilterChange,
    */
};


// ============================================================
// 第五部分：可选 - 页面加载时恢复筛选条件（增强功能）
// ============================================================

/**
 * 从localStorage恢复上次的筛选条件
 * 在onMounted生命周期钩子中调用
 */
const restoreFilterConditions = () => {
    try {
        const saved = localStorage.getItem('outbound_filter_conditions');
        if (saved) {
            const parsed = JSON.parse(saved);
            Object.assign(filterConditions, parsed);
            console.log('✅ 已恢复上次保存的筛选条件');

            // 如果有自定义日期范围，需要将字符串转换为Date对象
            if (filterConditions.timeRange === 'custom' &&
                Array.isArray(filterConditions.customDateRange) &&
                filterConditions.customDateRange.length === 2) {

                filterConditions.customDateRange = [
                    new Date(filterConditions.customDateRange[0]),
                    new Date(filterConditions.customDateRange[1])
                ];
            }
        }
    } catch (error) {
        console.warn('⚠️ 恢复筛选条件失败:', error);
    }
};

/**
 * 保存当前筛选条件到localStorage
 * 在筛选条件变化时调用
 */
const saveFilterConditions = () => {
    try {
        localStorage.setItem('outbound_filter_conditions', JSON.stringify(filterConditions));
    } catch (error) {
        console.warn('⚠️ 保存筛选条件失败:', error);
    }
};

// 在onMounted中调用恢复函数
/*
onMounted(async () => {
    // ... 其他初始化代码 ...

    // 恢复筛选条件
    restoreFilterConditions();

    // ... 其他初始化代码 ...
});
*/


// ============================================================
// 第六部分：可选 - 导出功能增强（使用筛选后的数据）
// ============================================================

/**
 * 导出筛选后的出库记录到Excel
 * 只导出当前筛选结果，而不是全部数据
 */
const exportFilteredToExcel = async () => {
    if (filteredOutboundRecords.value.length === 0) {
        ElMessage.warning('⚠️ 当前没有可导出的数据');
        return;
    }

    try {
        ElMessage.info('📤 正在准备导出数据...');

        // 准备导出数据
        const exportData = filteredOutboundRecords.value.map((record, index) => ({
            '序号': index + 1,
            '出库单号': record.ref_no || '',
            '批号': record.batch_no || '',
            '车号': record.vehicle_no || '',
            '出库类型': getOutTypeName(record.out_type),
            '出库重量(吨)': parseFloat(record.change_weight || record.out_weight || 0).toFixed(3),
            '出库金额(元)': Math.abs(parseFloat(record.total_amount || 0)),
            '出库日期': new Date(record.created_at).toLocaleDateString(),
            '备注': record.remark || ''
        }));

        // 创建工作簿
        const wb = XLSX.utils.book_new();
        const ws = XLSX.utils.json_to_sheet(exportData);

        // 设置列宽
        ws['!cols'] = [
            { wch: 6 },   // 序号
            { wch: 18 },  // 出库单号
            { wch: 14 },  // 批号
            { wch: 12 },  // 车号
            { wch: 10 },  // 出库类型
            { wch: 14 },  // 出库重量
            { wch: 14 },  // 出库金额
            { wch: 14 },  // 出库日期
            { wch: 30 }   // 备注
        ];

        XLSX.utils.book_append_sheet(wb, ws, '出库记录(筛选结果)');

        // 生成文件名（包含时间戳和筛选条件信息）
        const timestamp = new Date().toISOString().slice(0, 10);
        let filename = `出库记录_${timestamp}`;
        if (filterConditions.timeRange) {
            filename += `_${filterConditions.timeRange}`;
        }
        if (filterConditions.outType) {
            filename += `_类型${filterConditions.outType}`;
        }
        filename += '.xlsx';

        // 下载文件
        XLSX.writeFile(wb, filename);

        ElMessage.success(`✅ 成功导出 ${filteredOutboundRecords.value.length} 条记录到 ${filename}`);
        console.log('📤 导出完成:', filename);

    } catch (error) {
        console.error('❌ 导出Excel失败:', error);
        ElMessage.error('❌ 导出失败: ' + error.message);
    }
};


// ============================================================
// 第七部分：使用示例和最佳实践
// ============================================================

/**
 * 示例1：监听筛选结果变化，自动执行某些操作
 */
watch(filteredOutboundRecords, (newVal, oldVal) => {
    console.log(`📊 筛选结果变化: ${oldVal?.length || 0} -> ${newVal.length} 条`);

    // 可以在这里添加逻辑，例如：
    // - 当结果数量变化时显示提示
    // - 自动调整分页
    // - 触发数据分析
}, { deep: true });

/**
 * 示例2：组合使用多个计算属性进行复杂的数据分析
 */
const advancedAnalytics = computed(() => {
    const records = filteredOutboundRecords.value;

    if (records.length === 0) {
        return null;
    }

    // 计算重量分布区间
    const weightRanges = {
        light: records.filter(r => parseFloat(r.change_weight || r.out_weight || 0) < 5).length,
        medium: records.filter(r => {
            const w = parseFloat(r.change_weight || r.out_weight || 0);
            return w >= 5 && w < 15;
        }).length,
        heavy: records.filter(r => parseFloat(r.change_weight || r.out_weight || 0) >= 15).length
    };

    // 计算最活跃的时间段（按小时）
    const hourDistribution = {};
    records.forEach(r => {
        const hour = new Date(r.created_at).getHours();
        hourDistribution[hour] = (hourDistribution[hour] || 0) + 1;
    });

    const peakHour = Object.entries(hourDistribution)
        .sort((a, b) => b[1] - a[1])[0];

    return {
        weightRanges,
        peakHour: peakHour ? `${peakHour[0]}:00-${parseInt(peakHour[0]) + 1}:00 (${peakHour[1]}笔)` : '无数据',
        totalRecords: records.length
    };
});


// ============================================================
// 第八部分：调试和测试辅助函数
// ============================================================

/**
 * 调试函数：打印当前的筛选条件和结果统计
 * 在浏览器控制台调用: window.debugFilterStats()
 */
window.debugFilterStats = () => {
    console.group('🔍 增强版筛选系统调试信息');
    console.log('筛选条件:', JSON.parse(JSON.stringify(filterConditions)));
    console.log('激活条件数:', activeFilterCount.value);
    console.log('原始数据量:', outboundHistoryData.value.length);
    console.log('筛选后数量:', filteredOutboundRecords.value.length);
    console.log('统计数据:', enhancedStats.value);
    console.log('按类型分组:', statsGroupedByType.value);
    console.log('按日期分组:', statsGroupedByDate.value);
    console.groupEnd();

    return {
        conditions: filterConditions,
        activeCount: activeFilterCount.value,
        originalCount: outboundHistoryData.value.length,
        filteredCount: filteredOutboundRecords.value.length,
        stats: enhancedStats.value
    };
};

/**
 * 测试函数：生成模拟数据进行功能验证
 * 在浏览器控制台调用: window.testWithMockData()
 */
window.testWithMockData = () => {
    const mockData = Array.from({ length: 100 }, (_, i) => ({
        id: i + 1,
        ref_no: `OUT${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${String(i + 1).padStart(3, '0')}`,
        batch_no: `BATCH${String(i + 1).padStart(4, '0')}`,
        vehicle_no: `京${['A', 'B', 'C', 'D'][i % 4]}${String(Math.floor(Math.random() * 100000)).padStart(5, '0')}`,
        out_type: (i % 3) + 1,
        change_weight: Math.random() * 25 + 1,
        out_weight: Math.random() * 25 + 1,
        total_amount: Math.floor(Math.random() * 50000) + 5000,
        created_at: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
        unit_price: 2000
    }));

    console.log('🧪 生成了', mockData.length, '条模拟数据');
    console.log('前5条数据:', mockData.slice(0, 5));

    // 测试筛选功能
    const testConditions = {
        timeRange: 'thisWeek',
        customDateRange: [],
        outType: '1',
        keyword: '',
        minWeight: 5,
        maxWeight: 15,
        minAmount: null,
        maxAmount: null
    };

    const filtered = EnhancedFilterStatsSystem.filterRecords(mockData, testConditions);
    const stats = EnhancedFilterStatsSystem.calculateBasicStats(filtered);

    console.log('📊 测试筛选条件:', testConditions);
    console.log('📊 筛选结果:', filtered.length, '条');
    console.log('📊 统计数据:', stats);

    return { mockData, filtered, stats };
};
