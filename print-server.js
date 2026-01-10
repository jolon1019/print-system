const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const express = require('express');
const bodyParser = require('body-parser');

// 全局未捕获异常处理器
process.on('uncaughtException', (error) => {
  console.error('【严重错误】未捕获的异常:', error);
  console.error('错误堆栈:', error.stack);
  log(`【严重错误】未捕获的异常: ${error.message}`, 'error');
  log(`错误堆栈: ${error.stack}`, 'error');
  // 不退出进程，继续运行
});

// 全局未处理Promise拒绝处理器
process.on('unhandledRejection', (reason, promise) => {
  console.error('【严重错误】未处理的Promise拒绝:', reason);
  log(`【严重错误】未处理的Promise拒绝: ${reason}`, 'error');
  // 不退出进程，继续运行
});

// 进程退出监听器
process.on('exit', (code) => {
  console.error(`【进程退出】服务器进程将退出，退出码: ${code}`);
  log(`【进程退出】服务器进程将退出，退出码: ${code}`, 'error');
});

// 进程被终止监听器
process.on('SIGINT', () => {
  console.error('【进程终止】收到SIGINT信号，正在执行优雅关闭...');
  log(`【进程终止】收到SIGINT信号，正在执行优雅关闭...`, 'error');
  
  // 通知所有客户端
  const shutdownMessage = JSON.stringify({
    type: 'server-shutdown',
    message: '服务器即将关闭',
    timestamp: new Date().toISOString()
  });
  
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(shutdownMessage);
      client.close();
    }
  });
  
  // 清理定时器
  clearInterval(cleanupInterval);
  clearInterval(statusInterval);
});

process.on('SIGTERM', () => {
  console.error('【进程终止】收到SIGTERM信号，正在执行优雅关闭...');
  log(`【进程终止】收到SIGTERM信号，正在执行优雅关闭...`, 'error');
  
  // 通知所有客户端
  const shutdownMessage = JSON.stringify({
    type: 'server-shutdown',
    message: '服务器即将关闭',
    timestamp: new Date().toISOString()
  });
  
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(shutdownMessage);
      client.close();
    }
  });
  
  // 清理定时器
  clearInterval(cleanupInterval);
  clearInterval(statusInterval);
});

// 创建Express应用
const app = express();
app.use(bodyParser.json({ limit: '10mb' }));

// 添加API端点用于提供打印模板
app.post('/api/print/template', (req, res) => {
  try {
    const data = req.body;
    const html = generatePrintTemplate(data);
    res.send(html);
  } catch (error) {
    console.error('生成打印模板失败:', error);
    res.status(500).send('生成打印模板失败');
  }
});

// 添加自动打印功能到模板
function addAutoPrintFunctionality(template, data) {
  // 检查是否启用自动打印（默认启用）
  const autoPrint = data.autoPrint !== false;
  const debugMode = data.debug === true;
  const keepOpen = data.keepOpen === true;
  
  // 自动打印的JavaScript代码
  const autoPrintScript = `
  <!-- 自动打印功能 -->
  <script>
    // 自动打印配置
    const autoPrintConfig = {
      autoPrint: ${autoPrint},
      delay: 800,
      debug: ${debugMode},
      keepOpen: ${keepOpen}
    };
    
    // 自动打印函数
    function autoPrint() {
      if (!autoPrintConfig.autoPrint) return;
      
      setTimeout(() => {
        try {
          if (window.print) {
            window.print();
            
            // 打印完成后处理
            if (!autoPrintConfig.keepOpen) {
              setTimeout(() => {
                if (window.opener) {
                  window.close();
                }
              }, 1000);
            }
            
            if (autoPrintConfig.debug) {
              console.log('自动打印已触发');
            }
          }
        } catch (error) {
          console.error('自动打印失败:', error);
        }
      }, autoPrintConfig.delay);
    }
    
    // 页面加载完成后执行自动打印
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', autoPrint);
    } else {
      autoPrint();
    }
    
    // 打印媒体查询样式
    const printStyle = document.createElement('style');
    printStyle.textContent = \`
      @media print {
        .no-print {
          display: none !important;
        }
        
        body {
          -webkit-print-color-adjust: exact !important;
          color-adjust: exact !important;
        }
      }
      
      @media screen {
        .print-only {
          display: none !important;
        }
      }
    \`;
    document.head.appendChild(printStyle);
    
    // 监听打印事件
    window.addEventListener('beforeprint', () => {
      if (autoPrintConfig.debug) {
        console.log('打印前事件触发');
      }
    });
    
    window.addEventListener('afterprint', () => {
      if (autoPrintConfig.debug) {
        console.log('打印后事件触发');
      }
    });
  </script>
  `;
  
  // 将自动打印脚本插入到body结束标签之前
  if (template.includes('</body>')) {
    template = template.replace('</body>', autoPrintScript + '\n</body>');
  } else {
    template += autoPrintScript;
  }
  
  return template;
}

// 生成打印模板的函数
function generatePrintTemplate(data) {
  // 出库单据打印（支持新的outbound类型）
  if (data.type === 'outbound' || data.type === 'delivery') {
    // 从模板文件读取内容
    const templatePath = path.join(__dirname, 'templates', 'shipment_note_primary.html');
    if (fs.existsSync(templatePath)) {
      let template = fs.readFileSync(templatePath, 'utf8');
      
      // 先把每行金额转为数字再求和，避免包含 ¥/逗号 时 parseFloat 返回 0
      const numericTotal = (data.batchItems || []).reduce((sum, item) => {
        const amt = parseFloat(String(item.totalAmount || '0').replace(/[^\d.-]/g, '')) || 0;
        return sum + amt;
      }, 0);
      const summaryTotal = data.summary?.totalAmount
        ? (parseFloat(String(data.summary.totalAmount).replace(/[^\d.-]/g, '')) || numericTotal)
        : numericTotal;
      const totalAmountDisplay = summaryTotal.toLocaleString('zh-CN', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      });
      
      // 计算总重量
      const totalWeight = (data.batchItems || []).reduce((sum, item) => {
        const weight = parseFloat(String(item.weight || '0').replace(/[^\d.-]/g, '')) || 0;
        return sum + weight;
      }, 0);
      const totalWeightDisplay = totalWeight.toLocaleString('zh-CN', {
        minimumFractionDigits: 3,
        maximumFractionDigits: 3
      });
      
      // 替换模板中的占位符
      template = template.replace(/\{\{title\}\}/g, data.title || '出库单')
                       .replace(/\{\{outNo\}\}/g, data.outNo || data.orderNo || 'N/A')
                       .replace(/\{\{outDate\}\}/g, data.outDate || data.date || new Date().toLocaleDateString('zh-CN'))
                       .replace(/\{\{unit\}\}/g, data.unit || 'N/A')
                       .replace(/\{\{vehicleNo\}\}/g, data.vehicleNo || '')
                       .replace(/\{\{remark\}\}/g, data.remark || '无')
                       .replace(/\{\{printTime\}\}/g, data.printTime || new Date().toLocaleString('zh-CN'))
                       .replace(/\{\{totalAmount\}\}/g, totalAmountDisplay)
                       .replace(/\{\{totalWeight\}\}/g, totalWeightDisplay);      
      // 生成表格内容
      const tableRows = data.batchItems.map((item, index) => {
        // 处理单价和总价，确保显示正确的格式
        const unitPrice = item.unitPrice || 'N/A';
        const totalAmount = item.totalAmount || 'N/A';
        
        return `
        <tr>
          <td>${index + 1}</td>
          <td>${item.specification || item.spec || 'N/A'}</td>
          <td>${item.material || 'N/A'}</td>
          <td>${item.batchNo || item.name || 'N/A'}</td>
          <td>${item.weight || item.quantity || '0'}</td>
          <td>${unitPrice}</td>
          <td>${totalAmount}</td>
        </tr>
      `;
      }).join('');
      
      template = template.replace(/\{\{tableContent\}\}/g, tableRows);
      
      // 添加自动打印功能到模板
      template = addAutoPrintFunctionality(template, data);
      
      return template;
    } else {
      // 如果模板文件不存在，给出明确错误提示
      throw new Error('找不到出库单模板文件: ' + templatePath);
    }
  }
  // 入库单据打印（支持inbound类型）
  else if (data.type === 'inbound') {
    let template = `
      <!DOCTYPE html>
      <html lang="zh-CN">
      <head>
        <meta charset="UTF-8">
        <title>${data.title || '入库单'}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 20px;
            font-size: 12pt;
          }
          h1 {
            text-align: center;
            color: #333;
            font-size: 18pt;
            margin-bottom: 20px;
          }
          .header {
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #333;
          }
          .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr; /* 两列布局 */
            gap: 10px 30px; /* 行间距10px，列间距30px */
          }
          .info-item {
            display: flex;
            align-items: center;
            min-height: 25px;
          }
          .info-label {
            font-weight: bold;
            min-width: 80px;
          }
          .info-value {
            flex: 1;
            margin-left: 10px;
            border-bottom: 1px dashed #ccc;
            padding-bottom: 2px;
            min-height: 20px;
          }
          .items {
            margin-top: 20px;
          }
          .table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
          }
          .table th,
          .table td {
            border: 1px solid #333;
            padding: 5px;
            text-align: center;
          }
          .table {
            table-layout: fixed;
          }
          .table th {
            background-color: #f0f0f0;
            font-weight: bold;
          }
          .total {
            margin-top: 20px;
            text-align: right;
            font-weight: bold;
            font-size: 14pt;
          }
          .signature {
            margin-top: 30px;
            display: flex;
            justify-content: space-between;
          }
          .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 10pt;
            color: #666;
          }
        </style>
      </head>
      <body>
        <h1>${data.title || '入库单'}</h1>
        
        <div class="header">
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">入库单号:</span>
              <span class="info-value">${data.inNo || data.orderNo || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="info-label">入库日期:</span>
              <span class="info-value">${data.inDate || data.date || new Date().toLocaleDateString('zh-CN')}</span>
            </div>
            <div class="info-item">
              <span class="info-label">供应商:</span>
              <span class="info-value">${data.supplier || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="info-label">车辆信息:</span>
              <span class="info-value">${data.vehicleInfo || 'N/A'}</span>
            </div>
          </div>
        </div>
        
        <div class="items">
          <table class="table">
            <thead>
              <tr>
                <th>序号</th>
                <th>品名</th>
                <th>规格</th>
                <th>重量</th>
                <th>单价</th>
                <th>金额</th>
              </tr>
            </thead>
            <tbody>
              ${data.items.map((item, index) => `
                <tr>
                  <td>${index + 1}</td>
                  <td>${item.name || 'N/A'}</td>
                  <td>${item.specification || 'N/A'}</td>
                  <td>${item.weight || '0'}</td>
                  <td>${item.unitPrice || 'N/A'}</td>
                  <td>${item.amount || 'N/A'}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
        
        <div class="total">
          合计金额: ${data.totalAmount || '0.00'}元
        </div>
        
        <div class="signature">
          <div>供应商签字: _________________</div>
          <div>仓库员签字: _________________</div>
        </div>
        
        <div class="footer">
          <p>备注: ${data.remark || '无'}</p>
          <p>${data.footer || '感谢合作'} · ${data.printTime || new Date().toLocaleString('zh-CN')}</p>
        </div>
      </body>
      </html>
    `;
    
    // 为入库单添加自动打印功能
    template = addAutoPrintFunctionality(template, data);
    return template;
  }
  // 默认模板
  else {
    let template = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>打印文档</title>
      </head>
      <body>
        <h1>打印文档</h1>
        <p>无法识别的打印类型</p>
      </body>
      </html>
    `;
    
    // 为默认模板也添加自动打印功能
    template = addAutoPrintFunctionality(template, data);
    return template;
  }
}

// 创建WebSocket服务器，监听17026端口
// 增加连接选项以提高稳定性
const wss = new WebSocket.Server({ 
  host: '127.0.0.1',
  port: 17026,
  perMessageDeflate: false, // 禁用压缩以减少复杂性
  maxPayload: 10 * 1024 * 1024 // 设置最大消息负载为10MB
});














// 启动HTTP服务器监听17027端口
const server = app.listen(17027, '0.0.0.0', () => {
  console.log('✅ HTTP API服务器已启动，监听端口 17027');
  console.log('📡 API地址: http://localhost:17027/api/print/template');
});

console.log('✅ WebSocket打印服务器已启动，监听端口 17026');
console.log('📡 服务器地址: ws://localhost:17026');
console.log('🌐 远程访问地址: wss://103.91.208.133:61098');
console.log('🌐 远程访问地址: wss://free.frpee.top:17025');

// 存储连接
const printers = new Map();        // 打印机客户端
const mobileClients = new Map();   // 移动端客户端
const printJobs = new Map();       // 打印任务记录

// 服务器信息
const serverInfo = {
  name: '热卷打印服务器',
  version: '1.0.0',
  startTime: new Date()
};

// 创建日志目录
const logDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// 日志函数
function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${type.toUpperCase()}] ${message}`;
  console.log(logMessage);
  
  // 写入日志文件
  const logFile = path.join(logDir, `${new Date().toISOString().split('T')[0]}.log`);
  fs.appendFileSync(logFile, logMessage + '\n', 'utf8');
}

wss.on('connection', (ws, req) => {
  const clientIp = req.socket.remoteAddress;
  const clientPort = req.socket.remotePort;
  const clientId = `${clientIp}:${clientPort}`;
  
  log(`新的客户端连接: ${clientId}`);
  
  // 移除严格的验证超时，改为更宽松的连接管理
  // FRP 穿透场景下，连接可能需要更长时间才能完成握手
  let validationTimeout = null;
  
  // 发送欢迎消息
  ws.send(JSON.stringify({
    type: 'welcome',
    message: '欢迎连接到热卷打印服务器',
    serverInfo: serverInfo,
    timestamp: new Date().toISOString()
  }));

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      log(`收到消息 [${data.type}]: ${clientId}`);
      
      // 清除验证超时
      if (validationTimeout) {
        clearTimeout(validationTimeout);
        validationTimeout = null;
      }
      
      handleMessage(ws, data, clientId);
    } catch (error) {
      log(`消息处理失败: ${error.message}`, 'error');
      log(`错误堆栈: ${error.stack}`, 'error');
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'error',
          message: '消息处理错误',
          error: error.message
        }));
      }
    }
  });
  
  ws.on('close', () => {
    log(`客户端连接关闭: ${clientId}`);
    let printerUpdated = false;
    
    // 清理打印机（直接删除，避免离线记录堆积）
    for (const [printerId, printer] of printers.entries()) {
      if (printer.ws === ws) {
        printers.delete(printerId);
        log(`打印机断开连接，已移除: ${printer.name} (${printerId})`);
        printerUpdated = true;
        break;
      }
    }
    
    // 清理移动端
    for (const [mobileId, mobileClient] of mobileClients.entries()) {
      if (mobileClient.ws === ws) {
        mobileClients.delete(mobileId);
        log(`移动端断开连接: ${mobileId}`);
        break;
      }
    }
    
    // 如果打印机列表有更新，广播更新
    if (printerUpdated) {
      broadcastPrinterList();
    }
  });

  ws.on('error', (error) => {
    log(`WebSocket错误: ${error.message}`, 'error');
    log(`错误堆栈: ${error.stack}`, 'error');
  });
});

// 处理消息
function handleMessage(ws, data, clientId) {
  try {
    log(`收到客户端 ${clientId} 的消息，类型: ${data.type}`, 'debug');
    // 先将数据转换为JSON字符串，确保可以被序列化
    const dataStr = JSON.stringify(data);
    log(`消息内容: ${dataStr}`, 'debug');
    
    switch (data.type) {
    case 'register-printer':
      registerPrinter(ws, data, clientId);
      break;
      
    case 'register-mobile':
      registerMobile(ws, data, clientId);
      break;
      
    case 'get-printers':
      sendPrinterList(ws);
      break;
      
    case 'send-print-job':
      forwardPrintJob(ws, data, clientId);
      break;
      
    case 'ping':
      handlePing(ws, data, clientId);
      // 直接回复pong消息
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now()
        }));
      }
      break;
      
    case 'job-update':
      try {
        log(`收到job-update消息，data类型: ${typeof data}`, 'debug');
        if (data) {
          log(`收到job-update消息内容: ${JSON.stringify(data)}`, 'debug');
        } else {
          log(`收到job-update消息，但data为空`, 'debug');
        }
        forwardJobUpdate(data);
      } catch (error) {
        log(`处理job-update消息失败: ${error.message}`, 'error');
        log(`错误堆栈: ${error.stack}`, 'error');
      }
      break;
      
    case 'test-print':
      handleTestPrint(ws, data, clientId);
      break;
      
    case 'update-printer-name':
      handleUpdatePrinterName(ws, data, clientId);
      break;
      
    case 'ack':
      // 客户端确认收到未知消息类型
      log(`客户端确认收到未知消息类型: ${data.originalType}`, 'debug');
      break;
      
    default:
      // 未定义的消息类型，回复错误
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'error',
          message: `未知的消息类型: ${data.type}`
        }));
      }
      log(`收到未知消息类型: ${data.type}`, 'warn');
    }
  } catch (error) {
    log(`处理客户端 ${clientId} 的消息时出错: ${error.message}`, 'error');
    log(`错误堆栈: ${error.stack}`, 'error');
    
    // 尝试向客户端发送错误信息
    try {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'error',
          message: '服务器内部错误'
        }));
      }
    } catch (sendError) {
      log(`向客户端 ${clientId} 发送错误信息时出错: ${sendError.message}`, 'error');
    }
  }
}

// 注册打印机
function registerPrinter(ws, data, clientId) {
  const printerId = data.printerId || `printer_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
  
  const printer = {
    id: printerId,
    ws: ws,
    name: data.name || '未命名打印机',
    location: data.location || '办公室',
    type: data.printerType || 'laser',
    status: 'online',
    connectionTime: new Date().toISOString(),
    lastPing: Date.now(),
    clientId: clientId,
    capabilities: data.capabilities || { paperSizes: ['A4'] }
  };
  
  printers.set(printerId, printer);
  
  log(`打印机注册成功: ${printer.name} (${printerId})`);
  
  // 确认注册
  ws.send(JSON.stringify({
    type: 'register-success',
    printerId: printerId,
    message: '打印机注册成功'
  }));
  
  // 广播更新打印机列表
  broadcastPrinterList();
}

// 注册移动端
function registerMobile(ws, data, clientId) {
  const mobileId = data.mobileId || `mobile_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
  
  const mobileClient = {
    id: mobileId,
    ws: ws,
    user: data.user || '未知用户',
    device: data.device || '未知设备',
    connectionTime: new Date().toISOString(),
    clientId: clientId
  };
  
  mobileClients.set(mobileId, mobileClient);
  
  log(`移动端注册成功: ${mobileClient.user} (${mobileId})`);
  
  ws.send(JSON.stringify({
    type: 'register-success',
    mobileId: mobileId,
    message: '移动端注册成功'
  }));
  
  // 立即发送打印机列表
  sendPrinterList(ws);
}

// 发送打印机列表
function sendPrinterList(ws) {
  const printerList = Array.from(printers.values()).map(printer => ({
    id: printer.id,
    name: printer.name,
    location: printer.location,
    type: printer.type,
    status: printer.status,
    connectionTime: printer.connectionTime,
    lastPing: printer.lastPing,
    capabilities: printer.capabilities
  }));
  
  ws.send(JSON.stringify({
    type: 'printer-list',
    data: printerList,
    count: printerList.length,
    timestamp: new Date().toISOString()
  }));
}

// 广播打印机列表更新
function broadcastPrinterList() {
  const printerList = Array.from(printers.values()).map(printer => ({
    id: printer.id,
    name: printer.name,
    location: printer.location,
    type: printer.type,
    status: printer.status,
    connectionTime: printer.connectionTime,
    lastPing: printer.lastPing,
    capabilities: printer.capabilities
  }));
  
  const broadcastData = {
    type: 'printer-list-update',
    data: printerList,
    count: printerList.length,
    timestamp: new Date().toISOString()
  };
  
  // 向所有移动端客户端广播
  mobileClients.forEach((mobileClient, mobileId) => {
    if (mobileClient.ws.readyState === WebSocket.OPEN) {
      mobileClient.ws.send(JSON.stringify(broadcastData));
    }
  });
  
  log(`广播打印机列表更新: ${printerList.length} 台打印机`);
}

// 转发打印任务
function forwardPrintJob(ws, data, clientId) {
  const { printerId, jobId, printData, user } = data;
  
  // 记录任务
  const jobRecord = {
    id: jobId,
    printerId: printerId,
    mobileClientId: clientId,
    user: user || '未知用户',
    status: 'pending',
    timestamp: new Date().toISOString(),
    printData: printData
  };
  
  printJobs.set(jobId, jobRecord);
  log(`收到打印任务: ${jobId} -> ${printerId}, 用户: ${user}`);
  
  // 查找打印机
  const printer = printers.get(printerId);
  if (!printer) {
    log(`打印机未找到: ${printerId}`, 'error');
    ws.send(JSON.stringify({
      type: 'print-error',
      jobId: jobId,
      message: '打印机未找到或离线'
    }));
    return;
  }
  
  if (printer.ws.readyState !== WebSocket.OPEN) {
    log(`打印机连接已关闭: ${printerId}`, 'error');
    printer.status = 'offline';
    broadcastPrinterList();
    
    ws.send(JSON.stringify({
      type: 'print-error',
      jobId: jobId,
      message: '打印机连接已断开'
    }));
    return;
  }
  
  // 更新任务状态
  jobRecord.status = 'sending';
  jobRecord.sentTime = new Date().toISOString();
  
  // 转发到打印机
  printer.ws.send(JSON.stringify({
    type: 'print-job',
    jobId: jobId,
    printData: printData,
    user: user,
    timestamp: new Date().toISOString(),
    // 添加自动打印配置
    autoPrint: data.autoPrint !== false, // 默认启用自动打印
    debug: data.debug === true,           // 调试模式
    keepOpen: data.keepOpen === true      // 打印后保持窗口打开
  }));
  
  log(`打印任务已转发: ${jobId} -> ${printer.name}`);
  
  // 通知移动端任务已发送
  ws.send(JSON.stringify({
    type: 'print-sent',
    jobId: jobId,
    printerName: printer.name,
    timestamp: new Date().toISOString()
  }));
  
  // 向所有移动端广播任务更新
  broadcastJobUpdate({
    jobId: jobId,
    printerId: printerId,
    printerName: printer.name,
    status: 'sending',
    timestamp: new Date().toISOString()
  });
}

// 处理心跳
function handlePing(ws, data, clientId) {
  // 更新打印机最后活跃时间
  for (const [printerId, printer] of printers.entries()) {
    if (printer.ws === ws) {
      printer.lastPing = Date.now();
      break;
    }
  }
  // pong消息已经在switch语句中直接发送，这里不再重复发送
}

// 转发任务状态更新
function forwardJobUpdate(data) {
  try {
    const { jobId, status, message } = data;
    
    const jobRecord = printJobs.get(jobId);
    if (jobRecord) {
      jobRecord.status = status;
      jobRecord.updateTime = new Date().toISOString();
      if (message) jobRecord.message = message;
      
      if (status === 'printing') {
        jobRecord.startTime = new Date().toISOString();
      } else if (status === 'completed') {
        jobRecord.endTime = new Date().toISOString();
        log(`打印任务完成: ${jobId}`);
      } else if (status === 'failed') {
        jobRecord.endTime = new Date().toISOString();
        log(`打印任务失败: ${jobId} - ${message}`, 'error');
      }
    }
    
    broadcastJobUpdate(data);
  } catch (error) {
    log(`转发任务状态更新失败: ${error.message}`, 'error');
    log(`错误堆栈: ${error.stack}`, 'error');
  }
}

// 广播任务更新
function broadcastJobUpdate(jobData) {
  try {
    mobileClients.forEach((mobileClient, mobileId) => {
      if (mobileClient && mobileClient.ws && mobileClient.ws.readyState === WebSocket.OPEN) {
        mobileClient.ws.send(JSON.stringify({
          type: 'job-update',
          ...jobData
        }));
      }
    });
  } catch (error) {
    log(`广播任务更新失败: ${error.message}`, 'error');
    log(`错误堆栈: ${error.stack}`, 'error');
  }
}

// 处理测试打印
function handleTestPrint(ws, data, clientId) {
  const printerId = data.printerId;
  const printer = printers.get(printerId);
  
  if (!printer) {
    ws.send(JSON.stringify({
      type: 'test-print-error',
      message: '打印机未找到'
    }));
    return;
  }
  
  const testJobId = `test_${Date.now()}`;
  const testData = {
    type: 'test',
    title: '打印机测试页',
    content: '热卷出库系统打印机连接测试',
    printerInfo: {
      name: printer.name,
      location: printer.location,
      type: printer.type
    },
    timestamp: new Date().toLocaleString('zh-CN'),
    message: '如果看到此页面，说明打印机连接正常'
  };
  
  printer.ws.send(JSON.stringify({
    type: 'print-job',
    jobId: testJobId,
    printData: testData,
    user: '测试用户',
    timestamp: new Date().toISOString()
  }));
  
  log(`测试打印任务已发送: ${testJobId} -> ${printer.name}`);
  
  ws.send(JSON.stringify({
    type: 'test-print-sent',
    jobId: testJobId,
    printerName: printer.name
  }));
}

// 处理更新打印机名称
function handleUpdatePrinterName(ws, data, clientId) {
  const { printerId, newName } = data;
  
  // 查找打印机
  const printer = printers.get(printerId);
  if (!printer) {
    ws.send(JSON.stringify({
      type: 'update-printer-error',
      message: '打印机未找到'
    }));
    return;
  }
  
  // 检查权限（只有该打印机的连接可以修改自己的名称）
  if (printer.ws !== ws) {
    ws.send(JSON.stringify({
      type: 'update-printer-error',
      message: '权限不足，只能修改自己的打印机名称'
    }));
    return;
  }
  
  // 更新打印机名称
  const oldName = printer.name;
  printer.name = newName;
  
  log(`打印机名称已更新: ${oldName} -> ${newName}`);
  
  // 确认更新
  ws.send(JSON.stringify({
    type: 'update-printer-success',
    message: '打印机名称更新成功',
    newName: newName
  }));
  
  // 广播更新后的打印机列表
  broadcastPrinterList();
}

// 定期清理离线打印机
const cleanupInterval = setInterval(() => {
  const now = Date.now();
  let updated = false;
  
  for (const [printerId, printer] of printers.entries()) {
    // 如果65秒内没有心跳，标记为离线（增加容错）
    if (now - printer.lastPing > 65000) {
      if (printer.status !== 'offline') {
        printer.status = 'offline';
        updated = true;
        log(`打印机自动标记为离线: ${printer.name} (${now - printer.lastPing}ms 无响应)`);
      }
    } else if (printer.status === 'offline') {
      // 如果重新活跃，标记为在线
      printer.status = 'online';
      updated = true;
      log(`打印机重新上线: ${printer.name}`);
    }
  }
  
  if (updated) {
    broadcastPrinterList();
  }
}, 15000); // 每15秒检查一次（降低频率减少负载）

// 服务器状态监控
const statusInterval = setInterval(() => {
  const stats = {
    printers: printers.size,
    mobileClients: mobileClients.size,
    printJobs: printJobs.size,
    uptime: Math.floor((Date.now() - serverInfo.startTime) / 1000)
  };
  
  log(`服务器状态: ${JSON.stringify(stats)}`, 'debug');
}, 30000);

// 全局异常处理程序已移至文件顶部

// 优雅关闭
process.on('SIGINT', () => {
  log('正在关闭服务器...');
  
  // 通知所有客户端
  const shutdownMessage = JSON.stringify({
    type: 'server-shutdown',
    message: '服务器即将关闭',
    timestamp: new Date().toISOString()
  });
  
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(shutdownMessage);
      client.close();
    }
  });
  
  // 关闭HTTP服务器
  server.close(() => {
    console.log('HTTP服务器已关闭');
  });
  
});

// 导出服务器实例（用于测试）
module.exports = { wss, printers, mobileClients, printJobs };