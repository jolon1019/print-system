const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://likgolefqrhntbiscxdr.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxpa2dvbGVmcXJobnRiaXNjeGRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyMTk4NjUsImV4cCI6MjA4MTc5NTg2NX0.LIRHcrP7ZcZl2RUkDnwRcEnCy1WrnC0AMXvrMkt2UP4';

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

class InventoryTransferService {
  async transferOwnership(inventoryId, toUnit, operatorId, operatorName, reason = '') {
    try {
      const { data: inventory, error: inventoryError } = await supabase
        .from('inventory')
        .select('*')
        .eq('id', inventoryId)
        .single();

      if (inventoryError) throw inventoryError;
      if (!inventory) throw new Error('库存记录不存在');

      const fromUnit = inventory.unit;

      if (fromUnit === toUnit) {
        throw new Error('不能将货物转让给同一单位');
      }

      const { error: updateError } = await supabase
        .from('inventory')
        .update({ 
          unit: toUnit,
          updated_at: new Date().toISOString()
        })
        .eq('id', inventoryId);

      if (updateError) throw updateError;

      const { error: transferError } = await supabase
        .from('inventory_transfer')
        .insert({
          inventory_id: inventoryId,
          batch_no: inventory.batch_no,
          from_unit: fromUnit,
          to_unit: toUnit,
          transfer_date: new Date().toISOString(),
          transfer_reason: reason,
          operator_id: operatorId,
          operator_name: operatorName,
          status: 1
        });

      if (transferError) throw transferError;

      const { error: outboundError } = await supabase
        .from('outbound')
        .insert({
          inventory_id: inventoryId,
          batch_no: inventory.batch_no,
          unit: fromUnit,
          material: inventory.material,
          specification: inventory.specification,
          stock_weight: parseFloat(inventory.weight),
          out_weight: parseFloat(inventory.weight),
          unit_price: 0,
          total_amount: 0,
          out_type: 4,
          out_date: new Date().toISOString().split('T')[0],
          vehicle_no: inventory.vehicle_no || '',
          remark: `货权转让：${fromUnit} → ${toUnit}，原因：${reason}`,
          ref_no: `TRANSFER-${Date.now()}`
        });

      if (outboundError) throw outboundError;

      return {
        success: true,
        message: '货权转让成功，已为原单位创建出库记录',
        data: {
          inventoryId,
          batchNo: inventory.batch_no,
          fromUnit,
          toUnit
        }
      };
    } catch (error) {
      console.error('货权转让失败:', error);
      return {
        success: false,
        message: error.message || '货权转让失败',
        error: error
      };
    }
  }

  async getTransferHistory(filters = {}) {
    try {
      let query = supabase
        .from('inventory_transfer')
        .select(`
          *,
          inventory:inventory_id (
            batch_no,
            material,
            specification,
            weight,
            storage_location
          )
        `)
        .order('transfer_date', { ascending: false });

      if (filters.fromUnit) {
        query = query.eq('from_unit', filters.fromUnit);
      }

      if (filters.toUnit) {
        query = query.eq('to_unit', filters.toUnit);
      }

      if (filters.batchNo) {
        query = query.ilike('batch_no', `%${filters.batchNo}%`);
      }

      if (filters.startDate) {
        query = query.gte('transfer_date', filters.startDate);
      }

      if (filters.endDate) {
        query = query.lte('transfer_date', filters.endDate);
      }

      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      const { data, error } = await query;

      if (error) throw error;

      return {
        success: true,
        data: data || []
      };
    } catch (error) {
      console.error('获取转让历史失败:', error);
      return {
        success: false,
        message: error.message || '获取转让历史失败',
        error: error
      };
    }
  }

  async getTransferById(transferId) {
    try {
      const { data, error } = await supabase
        .from('inventory_transfer')
        .select(`
          *,
          inventory:inventory_id (
            batch_no,
            material,
            specification,
            weight,
            storage_location,
            in_date,
            status
          )
        `)
        .eq('id', transferId)
        .single();

      if (error) throw error;

      return {
        success: true,
        data: data
      };
    } catch (error) {
      console.error('获取转让记录失败:', error);
      return {
        success: false,
        message: error.message || '获取转让记录失败',
        error: error
      };
    }
  }

  async cancelTransfer(transferId) {
    try {
      const { data: transfer, error: transferError } = await supabase
        .from('inventory_transfer')
        .select('*')
        .eq('id', transferId)
        .single();

      if (transferError) throw transferError;
      if (!transfer) throw new Error('转让记录不存在');
      if (transfer.status !== 1) throw new Error('只能取消已完成的转让');

      const { error: updateError } = await supabase
        .from('inventory_transfer')
        .update({ 
          status: 2,
          updated_at: new Date().toISOString()
        })
        .eq('id', transferId);

      if (updateError) throw updateError;

      const { error: inventoryError } = await supabase
        .from('inventory')
        .update({ 
          unit: transfer.from_unit,
          updated_at: new Date().toISOString()
        })
        .eq('id', transfer.inventory_id);

      if (inventoryError) throw inventoryError;

      const { error: deleteOutboundError } = await supabase
        .from('outbound')
        .delete()
        .eq('inventory_id', transfer.inventory_id)
        .eq('out_type', 4)
        .eq('unit', transfer.from_unit);

      if (deleteOutboundError) {
        console.error('删除出库记录失败:', deleteOutboundError);
      }

      return {
        success: true,
        message: '转让记录已取消，货物已恢复到原单位，出库记录已删除'
      };
    } catch (error) {
      console.error('取消转让失败:', error);
      return {
        success: false,
        message: error.message || '取消转让失败',
        error: error
      };
    }
  }

  async getTransferStatistics(filters = {}) {
    try {
      let query = supabase
        .from('inventory_transfer')
        .select('*');

      if (filters.startDate) {
        query = query.gte('transfer_date', filters.startDate);
      }

      if (filters.endDate) {
        query = query.lte('transfer_date', filters.endDate);
      }

      const { data, error } = await query;

      if (error) throw error;

      const transfers = data || [];
      
      const statistics = {
        totalTransfers: transfers.length,
        completedTransfers: transfers.filter(t => t.status === 1).length,
        cancelledTransfers: transfers.filter(t => t.status === 2).length,
        uniqueFromUnits: [...new Set(transfers.map(t => t.from_unit))].length,
        uniqueToUnits: [...new Set(transfers.map(t => t.to_unit))].length,
        transfersByUnit: {}
      };

      transfers.forEach(transfer => {
        if (!statistics.transfersByUnit[transfer.from_unit]) {
          statistics.transfersByUnit[transfer.from_unit] = {
            outCount: 0,
            inCount: 0
          };
        }
        statistics.transfersByUnit[transfer.from_unit].outCount++;

        if (!statistics.transfersByUnit[transfer.to_unit]) {
          statistics.transfersByUnit[transfer.to_unit] = {
            outCount: 0,
            inCount: 0
          };
        }
        statistics.transfersByUnit[transfer.to_unit].inCount++;
      });

      return {
        success: true,
        data: statistics
      };
    } catch (error) {
      console.error('获取转让统计失败:', error);
      return {
        success: false,
        message: error.message || '获取转让统计失败',
        error: error
      };
    }
  }
}

module.exports = InventoryTransferService;
