const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

// 配置定义
const config = {
  serverAddress: 'ws://localhost:17026', // WebSocket服务器地址
  reconnectInterval: 5000, // 重连间隔（毫秒）增加到5秒，避免过于频繁重连
  logDirectory: './logs' // 日志目录
};

// 创建日志目录
const logDir = path.join(__dirname, config.logDirectory);

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// 日志配置
const LOG_CONFIG = {
  maxSize: 100 * 1024 * 1024, // 100MB
  maxFiles: 10 // 最多保留10个历史日志文件
};

// 日志函数
function log(message, type = 'info') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] [${type.toUpperCase()}] ${message}`;
  console.log(logMessage);
  
  const dateStr = new Date().toISOString().split('T')[0];
  let logFile = path.join(logDir, `print-client-${dateStr}.log`);
  
  // 检查日志文件大小，如果超过限制则轮转
  if (fs.existsSync(logFile)) {
    const stats = fs.statSync(logFile);
    if (stats.size >= LOG_CONFIG.maxSize) {
      // 轮转日志文件
      let counter = 1;
      let rotatedFile;
      
      // 找到可用的轮转文件名
      do {
        rotatedFile = path.join(logDir, `print-client-${dateStr}.${counter}.log`);
        counter++;
      } while (fs.existsSync(rotatedFile) && counter <= LOG_CONFIG.maxFiles);
      
      // 重命名当前日志文件
      fs.renameSync(logFile, rotatedFile);
      
      // 清理过期的轮转日志
      cleanupOldLogs(dateStr);
    }
  }
  
  // 写入日志文件
  fs.appendFileSync(logFile, logMessage + '\n', 'utf8');
}

// 清理过期的轮转日志
function cleanupOldLogs(dateStr) {
  try {
    const files = fs.readdirSync(logDir);
    const logFiles = files
      .filter(f => f.startsWith(`print-client-${dateStr}`) && f.endsWith('.log'))
      .sort((a, b) => {
        // 按修改时间排序
        const statA = fs.statSync(path.join(logDir, a));
        const statB = fs.statSync(path.join(logDir, b));
        return statA.mtime - statB.mtime;
      });
    
    // 删除超过最大数量的旧日志
    while (logFiles.length > LOG_CONFIG.maxFiles) {
      const oldFile = logFiles.shift();
      fs.unlinkSync(path.join(logDir, oldFile));
    }
  } catch (error) {
    console.error('清理旧日志失败:', error);
  }
}

// WebSocket连接
let ws = null;
let reconnectTimer = null;
let heartbeatInterval = null;
let connectionAttempts = 0; // 连接尝试次数
const maxConnectionAttempts = 5; // 最大连接尝试次数
let globalPrinterId = null; // 全局打印机ID

// 连接到WebSocket服务器
function connect() {
  log('正在连接到WebSocket服务器...');
  
  try {
    ws = new WebSocket(config.serverAddress);
    
    ws.on('open', () => {
      log('WebSocket服务器连接成功');
      
      // 注册打印机
      registerPrinter();
      
      // 清除重连计时器
      if (reconnectTimer) {
        clearTimeout(reconnectTimer);
        reconnectTimer = null;
      }
      
      // 启动心跳
      if (heartbeatInterval) {
        clearInterval(heartbeatInterval);
      }
      // 每20秒发送一次心跳（提高频率增强稳定性）
      heartbeatInterval = setInterval(() => {
        if (ws && ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'ping', timestamp: Date.now() }));
        }
      }, 20000);
    });
    
    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        handleMessage(data);
      } catch (error) {
        log(`消息解析失败: ${error.message}`, 'error');
      }
    });
    
    ws.on('close', () => {
      log('WebSocket服务器连接关闭');
      
      // 停止心跳
      if (heartbeatInterval) {
        clearInterval(heartbeatInterval);
        heartbeatInterval = null;
      }
      
      // 尝试重连
      scheduleReconnect();
    });
    
    ws.on('error', (error) => {
      log(`WebSocket错误: ${error.message}`, 'error');
      // 记录错误但不立即重连，等待close事件处理
    });
    
  } catch (error) {
    log(`连接失败: ${error.message}`, 'error');
    scheduleReconnect();
  }
}

// 注册打印机
function registerPrinter() {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    return;
  }
  
  // 检查是否存在配置文件
  const configPath = path.join(__dirname, 'printer-config.json');
  if (fs.existsSync(configPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      if (config.printerName) {
        // 使用配置文件中的打印机名称
        const printerData = {
          type: 'register-printer',
          name: config.printerName,
          location: config.location || '本地',
          printerType: 'laser',
          capabilities: {
            paperSizes: ['A4']
          }
        };
        
        ws.send(JSON.stringify(printerData));
        log(`已注册打印机: ${config.printerName} (来自配置文件)`);
        return;
      }
    } catch (error) {
      log(`读取打印机配置文件失败: ${error.message}`, 'error');
    }
  }
  
  // 获取本地打印机信息
  getLocalPrinters((printers) => {
    // 使用第一个可用打印机
    const defaultPrinter = printers[0] || { name: '默认打印机', location: '本地' };
    
    const printerData = {
      type: 'register-printer',
      name: defaultPrinter.name,
      location: defaultPrinter.location || '本地',
      printerType: 'laser',
      capabilities: {
        paperSizes: ['A4']
      }
    };
    
    ws.send(JSON.stringify(printerData));
    log(`已注册打印机: ${defaultPrinter.name}`);
  });
}

// 获取本地打印机列表（Windows）
function getLocalPrinters(callback) {
  exec('wmic printer list brief', (error, stdout, stderr) => {
    if (error) {
      log(`获取打印机列表失败: ${error.message}`, 'error');
      callback([]);
      return;
    }
    
    if (stderr) {
      log(`获取打印机列表警告: ${stderr}`, 'warn');
    }
    
    // 解析输出
    const printers = [];
    const lines = stdout.trim().split('\n');
    
    if (lines.length > 1) {
      // 跳过标题行
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (line) {
          const parts = line.split(/\s+/);
          const name = parts[0];
          printers.push({ name: name });
        }
      }
    }
    
    callback(printers);
  });
}

// 处理WebSocket消息
function handleMessage(data) {
  switch (data.type) {
    case 'register-success':
      log(`打印机注册成功，ID: ${data.printerId}`);
      // 保存打印机ID用于后续操作
      globalPrinterId = data.printerId;
      break;
      
    case 'update-printer-success':
      log(`打印机名称更新成功: ${data.newName}`);
      break;
      
    case 'update-printer-error':
      log(`打印机名称更新失败: ${data.message}`, 'error');
      break;
      
    case 'print-job':
      handlePrintJob(data);
      break;
      
    case 'ping':
      // 回复心跳
      log(`收到服务器ping消息，回复pong`);
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
      }
      break;
      
    default:
      log(`收到未知消息类型: ${data.type}`, 'warn');
      // 对于未知消息类型，发送确认回复以避免服务器端错误
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ 
          type: 'ack', 
          originalType: data.type,
          message: '客户端已收到未知类型消息'
        }));
      }
  }
}

// 处理打印任务
function handlePrintJob(data) {
  const { jobId, printData, user } = data;
  
  log(`收到打印任务: ${jobId}，用户: ${user}`);
  
  // 发送任务开始状态
  sendJobUpdate(jobId, 'printing', '开始打印...');
  
  try {
    // 生成打印文件
    const tempDir = path.join(__dirname, 'temp');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }
    
    // 生成HTML文件
    const htmlContent = generatePrintHTML(printData);
    const htmlFile = path.join(tempDir, `print_${jobId}.html`);
    
    fs.writeFileSync(htmlFile, htmlContent, 'utf8');
    
    // 调用系统打印命令
    printHTMLFile(htmlFile, (success, message) => {
      if (success) {
        log(`打印任务 ${jobId} 完成`);
        sendJobUpdate(jobId, 'completed', '打印成功');
      } else {
        log(`打印任务 ${jobId} 失败: ${message}`, 'error');
        sendJobUpdate(jobId, 'failed', message);
      }
      
      // 清理临时文件
      setTimeout(() => {
        try {
          fs.unlinkSync(htmlFile);
        } catch (error) {
          log(`清理临时文件失败: ${error.message}`, 'error');
        }
      }, 5000);
    });
    
  } catch (error) {
    log(`处理打印任务 ${jobId} 失败: ${error.message}`, 'error');
    sendJobUpdate(jobId, 'failed', error.message);
  }
}

// 生成打印HTML内容
function generatePrintHTML(data) {
  // 如果是测试打印
  if (data.type === 'test') {
    return `
      <html lang="zh-CN">
      <head>
        <meta charset="UTF-8">
        <title>${data.title}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 20px;
            font-size: 12pt;
          }
          h1 {
            color: #333;
            font-size: 16pt;
            margin-bottom: 20px;
          }
          .content {
            margin: 20px 0;
            line-height: 1.5;
          }
          .info {
            margin-top: 20px;
            font-size: 10pt;
            color: #666;
          }
          .printer-info {
            background-color: #f0f0f0;
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
          }
        </style>
      </head>
      <body>
        <h1>${data.title}</h1>
        <div class="content">
          <p>${data.content}</p>
          <div class="printer-info">
            <p><strong>打印机:</strong> ${data.printerInfo.name}</p>
            <p><strong>位置:</strong> ${data.printerInfo.location}</p>
            <p><strong>类型:</strong> ${data.printerInfo.type}</p>
          </div>
          <p>${data.message}</p>
        </div>
        <div class="info">
          <p>打印时间: ${data.timestamp}</p>
          <p>热卷出库系统打印服务器</p>
        </div>
      </body>
      </html>
    `;
  } 
  // 出库单据打印（支持新的outbound类型）
  else if (data.type === 'outbound' || data.type === 'delivery') {
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
      const totalAmountDisplay = Math.ceil(summaryTotal).toLocaleString('zh-CN');
      
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
          <td>${item.batchNo || item.name || 'N/A'}</td>
          <td>${item.material || 'N/A'}</td>
          <td>${item.specification || item.spec || 'N/A'}</td>
          <td>${item.weight || item.quantity || '0'}</td>
          <td>${unitPrice}</td>
          <td>${totalAmount}</td>
        </tr>
      `;
      }).join('');
      
      template = template.replace(/\{\{tableContent\}\}/g, tableRows);
      
      return template;
    } else {




      // 如果模板文件不存在，给出明确错误提示
      throw new Error('找不到出库单模板文件: ' + templatePath);
    }
  }
  // 入库单据打印（支持inbound类型）
  else if (data.type === 'inbound') {
    return `
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
          .table th {
            background-color: #f0f0f0;
            font-weight: bold;
          }
          .total {
            margin-top: 20px;
            text-align: right;
            font-weight: bold;
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
              <span class="info-value">${data.inNo || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="info-label">入库日期:</span>
              <span class="info-value">${data.inDate || new Date().toLocaleDateString('zh-CN')}</span>
            </div>
            <div class="info-item">
              <span class="info-label">入库单位:</span>
              <span class="info-value">${data.unit || 'N/A'}</span>
            </div>
            <div class="info-item">
              <span class="info-label">车牌号:</span>
              <span class="info-value">${data.vehicleNo || ''}</span>
            </div>
          </div>
        </div>
        
        <div class="items">
          <table class="table">
            <thead>
              <tr>
                <th>序号</th>
                <th>批次号</th>
                <th>材质</th>
                <th>规格</th>
                <th>重量</th>
                <th>运费</th>
              </tr>
            </thead>
            <tbody>
              ${data.batchItems.map((item, index) => `
                <tr>
                  <td>${index + 1}</td>
                  <td>${item.batchNo || 'N/A'}</td>
                  <td>${item.material || 'N/A'}</td>
                  <td>${item.specification || 'N/A'}</td>
                  <td>${item.weight || '0'}</td>
                  <td>${item.transportFee || '无'}</td>
                </tr>
              `).join('')}
            </tbody>
          </ta
          
          ble>
        </div>
        
        <div class="total">
          合计: ${data.summary?.totalWeight || '0'} 吨
        </div>
        
        <div class="footer">
          <p>备注: ${data.remark || '无'}</p>
          <p>${data.footer || '请核对入库信息，确认无误后签字'} · ${data.printTime || new Date().toLocaleString('zh-CN')}</p>
        </div>
      </body>
      </html>
    `;
  }
  // 默认打印内容
  else {
    return `
      <!DOCTYPE html>
      <html lang="zh-CN">
      <head>
        <meta charset="UTF-8">
        <title>打印内容</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 20px;
            font-size: 12pt;
          }
          .content {
            margin: 20px 0;
            line-height: 1.5;
          }
        </style>
      </head>
      <body>
        <div class="content">
          ${JSON.stringify(data, null, 2)}
        </div>
      </body>
      </html>
    `;
  }
}

// 打印HTML文件（Windows）
function printHTMLFile(filePath, callback) {
  // 首先尝试通过系统默认浏览器打开并打印
  // 使用PowerShell启动默认浏览器并打开HTML文件
  const cmd = `powershell -Command "Start-Process \"${filePath}\""`;
  
  exec(cmd, (error, stdout, stderr) => {
    if (error) {
      log(`通过浏览器打开文件失败: ${error.message}`, 'warn');
      
      // 如果通过浏览器打开失败，回退到原来的打印方法
      // 使用PowerShell执行打印命令，支持更多CSS样式
      const fallbackCmd = `powershell -Command "Start-Process -FilePath '${filePath}' -Verb Print"`;
      
      exec(fallbackCmd, (fallbackError, fallbackStdout, fallbackStderr) => {
        if (fallbackError) {
          // 如果PowerShell方法失败，回退到原来的rundll32方法
          log(`PowerShell打印方法失败，回退到rundll32方法: ${fallbackError.message}`, 'warn');
          const lastFallbackCmd = `rundll32.exe mshtml.dll,PrintHTML "${filePath}"`;
          exec(lastFallbackCmd, (lastFallbackError, lastFallbackStdout, lastFallbackStderr) => {
            if (lastFallbackError) {
              callback(false, `打印命令执行失败: ${lastFallbackError.message}`);
              return;
            }
            
            if (lastFallbackStderr) {
              log(`打印命令警告: ${lastFallbackStderr}`, 'warn');
            }
            
            callback(true, '打印命令执行成功');
          });
          return;
        }
        
        if (fallbackStderr) {
          log(`打印命令警告: ${fallbackStderr}`, 'warn');
        }
        
        // 等待一段时间确保打印任务完成
        setTimeout(() => {
          callback(true, '打印命令执行成功');
        }, 3000);
      });
      return;
    }
    
    if (stderr) {
      log(`通过浏览器打开文件警告: ${stderr}`, 'warn');
    }
    
    // 等待一段时间确保浏览器打开
    setTimeout(() => {
      callback(true, '已在浏览器中打开文件，请在浏览器中完成打印操作');
    }, 3000);
  });
}

// 发送任务状态更新
function sendJobUpdate(jobId, status, message) {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    log('WebSocket未连接，无法发送任务更新', 'warn');
    return;
  }
  
  const updateData = {
    type: 'job-update',
    jobId: jobId,
    status: status,
    message: message
  };
  
  ws.send(JSON.stringify(updateData));
}

// 回复心跳
// 已经在handleMessage中直接处理，此函数不再使用

// 更新打印机名称
function updatePrinterName(newName) {
  if (!ws || ws.readyState !== WebSocket.OPEN) {
    log('WebSocket未连接，无法更新打印机名称', 'error');
    return;
  }
  
  if (!globalPrinterId) {
    log('打印机尚未注册，无法更新名称', 'error');
    return;
  }
  
  const updateData = {
    type: 'update-printer-name',
    printerId: globalPrinterId,
    newName: newName
  };
  
  ws.send(JSON.stringify(updateData));
  log(`发送打印机名称更新请求: ${newName}`);
}

// 安排重连
function scheduleReconnect() {
  connectionAttempts++;
  
  // 如果超过最大连接尝试次数，延长重连间隔
  const actualReconnectInterval = connectionAttempts > maxConnectionAttempts 
    ? config.reconnectInterval * 3 
    : config.reconnectInterval;
  
  if (!reconnectTimer) {
    log(`将在 ${actualReconnectInterval}ms 后尝试重连... (第${connectionAttempts}次尝试)`);
    reconnectTimer = setTimeout(() => {
      connect();
    }, actualReconnectInterval);
  }
}

// 主程序入口
function main() {
  log('打印机客户端启动');
  log(`连接服务器: ${config.serverAddress}`);
  
  // 连接到服务器
  connect();
  
  // 定期发送心跳
  setInterval(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'pong', timestamp: Date.now() }));
    }
  }, 20000); // 每20秒发送一次心跳，与上面保持一致
}

// 示例：更新打印机名称的函数
// 可以在需要的时候调用此函数来更新打印机名称
function setCustomPrinterName(customName) {
  updatePrinterName(customName);
}

// 示例：根据配置文件设置打印机名称
function setPrinterNameFromConfig() {
  // 读取配置文件或环境变量中的打印机名称
  const configPath = path.join(__dirname, 'printer-config.json');
  
  if (fs.existsSync(configPath)) {
    try {
      const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      if (config.printerName) {
        setCustomPrinterName(config.printerName);
      }
    } catch (error) {
      log(`读取打印机配置文件失败: ${error.message}`, 'error');
    }
  }
}

// 启动主程序
main();

// 示例：在程序启动后的一段时间内尝试从配置文件设置打印机名称
setTimeout(() => {
  if (globalPrinterId) {
    setPrinterNameFromConfig();
  }
}, 5000); // 等待5秒确保注册完成

// 优雅退出
process.on('SIGINT', () => {
  log('正在关闭打印机客户端...');
  
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
  }
  
  if (ws) {
    ws.close();
  }
  
  log('打印机客户端已关闭');
  // 不退出进程，只清理资源
});