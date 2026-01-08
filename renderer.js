const { ipcRenderer, shell } = require('electron');
const os = require('os');
const path = require('path');

// 抑制常见的Electron内部错误
window.addEventListener('error', (event) => {
  if (event.message && event.message.includes('dragEvent')) {
    event.preventDefault();
    event.stopPropagation();
    return false;
  }
});

window.addEventListener('unhandledrejection', (event) => {
  if (event.reason && event.reason.toString().includes('dragEvent')) {
    event.preventDefault();
    event.stopPropagation();
    return false;
  }
});

const serviceStatus = {
  'print-server': 'stopped',
  'printer-client': 'stopped',
  'python-monitor': 'stopped'
};

const logs = [];
let currentFilter = 'all';

document.addEventListener('DOMContentLoaded', () => {
  initializeApp();
  setupEventListeners();
  updateSystemInfo();
  updateTime();
  setInterval(updateTime, 1000);
});

function initializeApp() {
  addLog('系统', '应用已初始化', 'info');
}

function setupEventListeners() {
  const navItems = document.querySelectorAll('.nav-item');
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      navItems.forEach(nav => nav.classList.remove('active'));
      item.classList.add('active');
      
      const tabId = item.dataset.tab;
      switchTab(tabId);
    });
  });

  ipcRenderer.on('service-status', (event, data) => {
    updateServiceStatus(data.service, data.status);
  });

  ipcRenderer.on('log-message', (event, data) => {
    addLog(data.service, data.message, data.type);
  });

  ipcRenderer.on('remote-url-updated', (event, data) => {
    if (data.success) {
      addLog('打印服务器', '远程访问地址已成功更新到文件', 'success');
    } else {
      addLog('打印服务器', `更新失败: ${data.error}`, 'error');
    }
  });
}

function switchTab(tabId) {
  const tabs = document.querySelectorAll('.tab-content');
  tabs.forEach(tab => tab.classList.remove('active'));
  
  const activeTab = document.getElementById(tabId);
  if (activeTab) {
    activeTab.classList.add('active');
  }
}

function startService(serviceName) {
  if (serviceStatus[serviceName] === 'running') {
    return;
  }

  addLog('系统', `正在启动 ${serviceName}...`, 'info');
  
  switch (serviceName) {
    case 'print-server':
      ipcRenderer.send('start-print-server');
      break;
    case 'printer-client':
      ipcRenderer.send('start-printer-client');
      break;
    case 'python-monitor':
      ipcRenderer.send('start-python-monitor');
      break;
  }
}

function stopService(serviceName) {
  if (serviceStatus[serviceName] === 'stopped') {
    return;
  }

  addLog('系统', `正在停止 ${serviceName}...`, 'info');
  
  switch (serviceName) {
    case 'print-server':
      ipcRenderer.send('stop-print-server');
      break;
    case 'printer-client':
      ipcRenderer.send('stop-printer-client');
      break;
    case 'python-monitor':
      ipcRenderer.send('stop-python-monitor');
      break;
  }
}

function updateServiceStatus(serviceName, status) {
  serviceStatus[serviceName] = status;
  
  const statusText = status === 'running' ? '运行中' : '已停止';
  const statusClass = status;
  
  const statusIndicators = document.querySelectorAll(`#${serviceName}-status`);
  statusIndicators.forEach(indicator => {
    indicator.classList.remove('running', 'stopped');
    indicator.classList.add(statusClass);
  });
  
  const cardStatuses = document.querySelectorAll(`#${serviceName}-card-status`);
  cardStatuses.forEach(cardStatus => {
    cardStatus.textContent = statusText;
    cardStatus.classList.remove('running', 'stopped');
    cardStatus.classList.add(statusClass);
  });
  
  const serviceStatuses = document.querySelectorAll(`#${serviceName}-service-status`);
  serviceStatuses.forEach(serviceStatus => {
    serviceStatus.textContent = statusText;
    serviceStatus.classList.remove('running', 'stopped');
    serviceStatus.classList.add(statusClass);
  });
  
  const startBtn = document.getElementById(`${serviceName}-start-btn`);
  const stopBtn = document.getElementById(`${serviceName}-stop-btn`);
  
  if (startBtn && stopBtn) {
    if (status === 'running') {
      startBtn.textContent = '已启动';
      startBtn.disabled = true;
      startBtn.classList.add('disabled');
      stopBtn.disabled = false;
      stopBtn.classList.remove('disabled');
    } else {
      startBtn.textContent = '启动';
      startBtn.disabled = false;
      startBtn.classList.remove('disabled');
      stopBtn.disabled = true;
      stopBtn.classList.add('disabled');
    }
  }
  
  addLog('系统', `${serviceName} 状态已更新: ${statusText}`, status === 'running' ? 'success' : 'warning');
}

function addLog(service, message, type = 'info') {
  const logEntry = {
    time: new Date().toLocaleTimeString(),
    service,
    message,
    type
  };
  
  logs.push(logEntry);
  
  if (currentFilter === 'all' || currentFilter === service) {
    renderLogEntry(logEntry);
  }
}

function renderLogEntry(logEntry) {
  const logsContent = document.getElementById('logs-content');
  const logDiv = document.createElement('div');
  logDiv.className = 'log-entry';
  
  const messageClass = logEntry.type !== 'info' ? logEntry.type : '';
  
  logDiv.innerHTML = `
    <span class="log-time">${logEntry.time}</span>
    <span class="log-service">${logEntry.service}</span>
    <span class="log-message ${messageClass}">${logEntry.message.trim()}</span>
  `;
  
  logsContent.appendChild(logDiv);
  logsContent.scrollTop = logsContent.scrollHeight;
}

function filterLogs() {
  const filter = document.getElementById('log-filter').value;
  currentFilter = filter;
  
  const logsContent = document.getElementById('logs-content');
  logsContent.innerHTML = '';
  
  const filteredLogs = filter === 'all' 
    ? logs 
    : logs.filter(log => log.service === filter);
  
  filteredLogs.forEach(log => renderLogEntry(log));
}

function clearLogs() {
  logs.length = 0;
  const logsContent = document.getElementById('logs-content');
  logsContent.innerHTML = '';
  addLog('系统', '日志已清空', 'info');
}

function updateSystemInfo() {
  const osInfo = document.getElementById('os-info');
  const nodeVersion = document.getElementById('node-version');
  const electronVersion = document.getElementById('electron-version');
  
  osInfo.textContent = `${os.type()} ${os.release()} ${os.arch()}`;
  nodeVersion.textContent = process.version;
  electronVersion.textContent = process.versions.electron;
  
  updateUptime();
  setInterval(updateUptime, 1000);
}

function updateUptime() {
  const uptimeElement = document.getElementById('uptime');
  const uptime = process.uptime();
  const hours = Math.floor(uptime / 3600);
  const minutes = Math.floor((uptime % 3600) / 60);
  const seconds = Math.floor(uptime % 60);
  
  uptimeElement.textContent = `${hours}小时 ${minutes}分钟 ${seconds}秒`;
}

function updateTime() {
  const timeElement = document.getElementById('current-time');
  const now = new Date();
  timeElement.textContent = now.toLocaleString('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });
}

function openKucuSystem() {
  const kucuFilePath = path.join('C:', 'Users', 'Administrator', 'Desktop', 'new', 'main.html');
  shell.openPath(kucuFilePath).then((error) => {
    if (error) {
      addLog('库粗系统', `打开失败: ${error}`, 'error');
    } else {
      addLog('库粗系统', '已成功打开', 'success');
      document.getElementById('kucu-system-status').textContent = '已打开';
      document.getElementById('kucu-system-status').classList.add('running');
    }
  });
}

function editRemoteAccessUrl() {
  const currentUrl = document.getElementById('remote-access-url').textContent;
  const newUrl = prompt('请输入新的远程访问地址:', currentUrl);
  
  if (newUrl && newUrl !== currentUrl) {
    if (newUrl.startsWith('ws://') || newUrl.startsWith('wss://')) {
      document.getElementById('remote-access-url').textContent = newUrl;
      addLog('打印服务器', `远程访问地址已更新为: ${newUrl}`, 'success');
      
      ipcRenderer.send('update-remote-url', newUrl);
    } else {
      alert('地址必须以 ws:// 或 wss:// 开头');
      addLog('打印服务器', '地址格式错误', 'error');
    }
  }
}
