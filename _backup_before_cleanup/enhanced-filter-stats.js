/**
 * 增强版出库记录筛选和统计系统
 * 功能特性：
 * 1. 多条件组合查询（时间、类型、关键词、数值范围）
 * 2. 实时数据统计分析
 * 3. 分组统计和趋势分析
 * 4. 可视化数据展示
 */

const EnhancedFilterStatsSystem = {
    /**
     * 初始化筛选条件状态
     */
    createFilterConditions() {
        return Vue.reactive({
            timeRange: '', // today, yesterday, thisWeek, thisMonth, lastMonth, custom
            customDateRange: [],
            outType: '',
            keyword: '',
            minWeight: null,
            maxWeight: null,
            minAmount: null,
            maxAmount: null
        });
    },

    /**
     * 计算当前激活的筛选条件数量
     */
    getActiveFilterCount(conditions) {
        let count = 0;
        if (conditions.timeRange) count++;
        if (conditions.outType) count++;
        if (conditions.keyword) count++;
        return count;
    },

    /**
     * 根据时间范围获取日期边界
     */
    getDateRange(timeRange, customDateRange) {
        const now = new Date();
        let startDate, endDate;

        switch (timeRange) {
            case 'today': {
                startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
                break;
            }
            case 'yesterday': {
                startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1);
                endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                break;
            }
            case 'thisWeek': {
                const dayOfWeek = now.getDay() || 7;
                startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - dayOfWeek + 1);
                endDate = new Date(startDate.getTime() + 7 * 24 * 60 * 60 * 1000);
                break;
            }
            case 'thisMonth': {
                startDate = new Date(now.getFullYear(), now.getMonth(), 1);
                endDate = new Date(now.getFullYear(), now.getMonth() + 1, 1);
                break;
            }
            case 'lastMonth': {
                startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1);
                endDate = new Date(now.getFullYear(), now.getMonth(), 1);
                break;
            }
            case 'custom': {
                if (customDateRange && customDateRange.length === 2) {
                    startDate = new Date(customDateRange[0]);
                    startDate.setHours(0, 0, 0, 0);
                    endDate = new Date(customDateRange[1]);
                    endDate.setHours(23, 59, 59, 999);
                }
                break;
            }
            default:
                return null;
        }

        return { startDate, endDate };
    },

    /**
     * 多条件组合筛选核心逻辑
     */
    filterRecords(records, conditions) {
        let filtered = [...records];

        // 时间范围筛选
        if (conditions.timeRange) {
            const dateRange = this.getDateRange(conditions.timeRange, conditions.customDateRange);
            if (dateRange) {
                filtered = filtered.filter(record => {
                    const recordDate = new Date(record.created_at);
                    return recordDate >= dateRange.startDate && recordDate <= dateRange.endDate;
                });
            }
        }

        // 出库类型筛选
        if (conditions.outType !== '') {
            filtered = filtered.filter(record => {
                const recordOutType = record.out_type || record.outType || record.change_type;
                return String(recordOutType) === conditions.outType;
            });
        }

        // 关键词搜索（支持车号、批号、单号）
        if (conditions.keyword) {
            const keyword = conditions.keyword.toLowerCase().trim();
            filtered = filtered.filter(record => {
                const searchFields = [
                    record.vehicle_no,
                    record.batch_no,
                    record.ref_no,
                    record.out_no
                ].filter(Boolean);

                return searchFields.some(field =>
                    field.toString().toLowerCase().includes(keyword)
                );
            });
        }

        // 重量范围筛选
        if (conditions.minWeight !== null || conditions.maxWeight !== null) {
            filtered = filtered.filter(record => {
                const weight = Math.abs(parseFloat(
                    record.change_weight ||
                    record.out_weight ||
                    0
                ) || 0);

                if (conditions.minWeight !== null && weight < conditions.minWeight) return false;
                if (conditions.maxWeight !== null && weight > conditions.maxWeight) return false;
                return true;
            });
        }

        // 金额范围筛选
        if (conditions.minAmount !== null || conditions.maxAmount !== null) {
            filtered = filtered.filter(record => {
                const amount = Math.abs(parseFloat(record.total_amount) || 0);

                if (conditions.minAmount !== null && amount < conditions.minAmount) return false;
                if (conditions.maxAmount !== null && amount > conditions.maxAmount) return false;
                return true;
            });
        }

        return filtered;
    },

    /**
     * 计算基础统计数据
     */
    calculateBasicStats(filteredRecords) {
        let totalWeight = 0;
        let totalAmount = 0;
        const weights = [];
        const amounts = [];

        filteredRecords.forEach(item => {
            const outWeightNum = Math.abs(parseFloat(
                item.change_weight ||
                item.out_weight ||
                0
            ) || 0);

            const totalAmountNum = Math.abs(parseFloat(item.total_amount) || 0);

            totalWeight += outWeightNum;
            totalAmount += totalAmountNum;
            weights.push(outWeightNum);
            amounts.push(totalAmountNum);
        });

        const recordCount = filteredRecords.length;

        return {
            recordCount,
            totalWeight: parseFloat(totalWeight.toFixed(3)),
            totalAmount: Math.ceil(totalAmount),
            avgWeight: recordCount > 0 ? parseFloat((totalWeight / recordCount).toFixed(3)) : 0,
            avgAmount: recordCount > 0 ? Math.ceil(totalAmount / recordCount) : 0,
            maxWeight: weights.length > 0 ? parseFloat(Math.max(...weights).toFixed(3)) : 0,
            minWeight: weights.length > 0 ? parseFloat(Math.min(...weights).toFixed(3)) : 0,
            maxAmount: amounts.length > 0 ? Math.max(...amounts) : 0,
            minAmount: amounts.length > 0 ? Math.min(...amounts) : 0
        };
    },

    /**
     * 按出库类型分组统计
     */
    calculateGroupedByType(filteredRecords, outTypeOptions) {
        const groups = {};

        outTypeOptions.forEach(opt => {
            groups[opt.type_code] = {
                typeName: opt.type_name,
                typeCode: opt.type_code,
                recordCount: 0,
                totalWeight: 0,
                totalAmount: 0
            };
        });

        filteredRecords.forEach(item => {
            const outType = item.out_type || item.outType || item.change_type;
            if (groups[outType]) {
                groups[outType].recordCount++;
                groups[outType].totalWeight += Math.abs(parseFloat(
                    item.change_weight ||
                    item.out_weight ||
                    0
                ) || 0);
                groups[outType].totalAmount += Math.abs(parseFloat(item.total_amount) || 0);
            }
        });

        Object.values(groups).forEach(group => {
            group.totalWeight = parseFloat(group.totalWeight.toFixed(3));
            group.totalAmount = Math.ceil(group.totalAmount);
        });

        return Object.values(groups);
    },

    /**
     * 按日期分组统计（用于趋势分析）
     */
    calculateGroupedByDate(filteredRecords, groupBy = 'day') {
        const groups = {};

        filteredRecords.forEach(item => {
            const date = new Date(item.created_at);
            let key;

            switch (groupBy) {
                case 'day':
                    key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
                    break;
                case 'week': {
                    const weekStart = new Date(date);
                    weekStart.setDate(date.getDate() - date.getDay());
                    key = `${weekStart.getFullYear()}-${String(weekStart.getMonth() + 1).padStart(2, '0')}-${String(weekStart.getDate()).padStart(2, '0')}`;
                    break;
                }
                case 'month':
                    key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
                    break;
                default:
                    key = date.toISOString().split('T')[0];
            }

            if (!groups[key]) {
                groups[key] = {
                    date: key,
                    recordCount: 0,
                    totalWeight: 0,
                    totalAmount: 0
                };
            }

            groups[key].recordCount++;
            groups[key].totalWeight += Math.abs(parseFloat(
                item.change_weight ||
                item.out_weight ||
                0
            ) || 0);
            groups[key].totalAmount += Math.abs(parseFloat(item.total_amount) || 0);
        });

        return Object.values(groups)
            .map(group => ({
                ...group,
                totalWeight: parseFloat(group.totalWeight.toFixed(3)),
                totalAmount: Math.ceil(group.totalAmount)
            }))
            .sort((a, b) => a.date.localeCompare(b.date));
    },

    /**
     * 防抖函数
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
};

// 导出模块（如果在Node.js环境）
if (typeof module !== 'undefined' && module.exports) {
    module.exports = EnhancedFilterStatsSystem;
}

// 浏览器环境下挂载到全局对象
if (typeof window !== 'undefined') {
    window.EnhancedFilterStatsSystem = EnhancedFilterStatsSystem;
}
