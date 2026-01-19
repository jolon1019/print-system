const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;
let printServerProcess = null;
let printerClientProcess = null;
let pythonMonitorProcess = null;

function createWindow() {
  console.log('正在创建 Electron 窗口...');
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 1000,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    icon: path.join(__dirname, 'icon.png'),
    title: '热卷打印管理系统'
  });

  console.log('正在加载 index.html...');
  mainWindow.loadFile('index.html');
  
  mainWindow.webContents.on('did-finish-load', () => {
    console.log('index.html 加载完成');
    mainWindow.show();
    mainWindow.focus();
  });
  
  mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.error('加载 index.html 失败:', errorCode, errorDescription);
  });

  mainWindow.on('closed', () => {
    console.log('窗口已关闭');
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  stopAllServices();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

ipcMain.on('start-print-server', () => {
  if (printServerProcess) {
    return;
  }

  printServerProcess = spawn('node', ['print-server.js'], {
    cwd: __dirname,
    shell: true
  });

  printServerProcess.stdout.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'print-server',
      message: data.toString(),
      type: 'info'
    });
  });

  printServerProcess.stderr.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'print-server',
      message: data.toString(),
      type: 'error'
    });
  });

  printServerProcess.on('close', (code) => {
    mainWindow?.webContents.send('service-status', {
      service: 'print-server',
      status: 'stopped'
    });
    printServerProcess = null;
  });

  mainWindow?.webContents.send('service-status', {
    service: 'print-server',
    status: 'running'
  });
});

ipcMain.on('stop-print-server', () => {
  if (printServerProcess) {
    printServerProcess.kill();
    printServerProcess = null;
    mainWindow?.webContents.send('service-status', {
      service: 'print-server',
      status: 'stopped'
    });
  }
});

ipcMain.on('start-printer-client', () => {
  if (printerClientProcess) {
    return;
  }

  printerClientProcess = spawn('node', ['printer-client.js'], {
    cwd: __dirname,
    shell: true
  });

  printerClientProcess.stdout.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'printer-client',
      message: data.toString(),
      type: 'info'
    });
  });

  printerClientProcess.stderr.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'printer-client',
      message: data.toString(),
      type: 'error'
    });
  });

  printerClientProcess.on('close', (code) => {
    mainWindow?.webContents.send('service-status', {
      service: 'printer-client',
      status: 'stopped'
    });
    printerClientProcess = null;
  });

  mainWindow?.webContents.send('service-status', {
    service: 'printer-client',
    status: 'running'
  });
});

ipcMain.on('stop-printer-client', () => {
  if (printerClientProcess) {
    printerClientProcess.kill();
    printerClientProcess = null;
    mainWindow?.webContents.send('service-status', {
      service: 'printer-client',
      status: 'stopped'
    });
  }
});

ipcMain.on('start-python-monitor', () => {
  if (pythonMonitorProcess) {
    return;
  }

  pythonMonitorProcess = spawn('python', ['python_monitor.py'], {
    cwd: __dirname,
    shell: true
  });

  pythonMonitorProcess.stdout.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'python-monitor',
      message: data.toString(),
      type: 'info'
    });
  });

  pythonMonitorProcess.stderr.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: 'python-monitor',
      message: data.toString(),
      type: 'error'
    });
  });

  pythonMonitorProcess.on('close', (code) => {
    mainWindow?.webContents.send('service-status', {
      service: 'python-monitor',
      status: 'stopped'
    });
    pythonMonitorProcess = null;
  });

  mainWindow?.webContents.send('service-status', {
    service: 'python-monitor',
    status: 'running'
  });
});

ipcMain.on('stop-python-monitor', () => {
  if (pythonMonitorProcess) {
    pythonMonitorProcess.kill();
    pythonMonitorProcess = null;
    mainWindow?.webContents.send('service-status', {
      service: 'python-monitor',
      status: 'stopped'
    });
  }
});

function stopAllServices() {
  if (printServerProcess) {
    printServerProcess.kill();
    printServerProcess = null;
  }
  if (printerClientProcess) {
    printerClientProcess.kill();
    printerClientProcess = null;
  }
  if (pythonMonitorProcess) {
    pythonMonitorProcess.kill();
    pythonMonitorProcess = null;
  }
}

ipcMain.on('update-remote-url', (event, newUrl) => {
  const fs = require('fs');
  const printServerPath = path.join(__dirname, 'print-server.js');
  
  try {
    let content = fs.readFileSync(printServerPath, 'utf8');
    
    const urlRegex = /console\.log\('🌐 远程访问地址: [^']+'\);/;
    const newLine = `console.log('🌐 远程访问地址: ${newUrl}');`;
    
    if (urlRegex.test(content)) {
      content = content.replace(urlRegex, newLine);
      fs.writeFileSync(printServerPath, content, 'utf8');
      
      mainWindow?.webContents.send('remote-url-updated', { success: true, url: newUrl });
    } else {
      mainWindow?.webContents.send('remote-url-updated', { success: false, error: '未找到远程访问地址行' });
    }
  } catch (error) {
    mainWindow?.webContents.send('remote-url-updated', { success: false, error: error.message });
  }
});

ipcMain.on('kill-port-17026', () => {
  const batPath = path.join(__dirname, 'kill-port-17026-en.bat');
  
  const killProcess = spawn('cmd.exe', ['/c', batPath], {
    cwd: __dirname,
    shell: true
  });

  killProcess.stdout.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: '库存系统',
      message: data.toString(),
      type: 'info'
    });
  });

  killProcess.stderr.on('data', (data) => {
    mainWindow?.webContents.send('log-message', {
      service: '库存系统',
      message: data.toString(),
      type: 'error'
    });
  });

  killProcess.on('close', (code) => {
    mainWindow?.webContents.send('log-message', {
      service: '库存系统',
      message: `端口清理完成，退出码: ${code}`,
      type: code === 0 ? 'success' : 'error'
    });
  });
});
