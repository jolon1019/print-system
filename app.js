const { spawn } = require('child_process');
const express = require('express');
const fs = require('fs');
const path = require('path');
const os = require('os');

class PrintMonitorManager {
    constructor() {
        this.app = express();
        this.pythonProcess = null;
        this.isRunning = false;
        this.logFile = path.join(__dirname, 'logs', 'monitor.log');
        this.restartAttempts = 0;
        this.maxRestartAttempts = 3;
        
        // 确保日志目录存在
        if (!fs.existsSync(path.join(__dirname, 'logs'))) {
            fs.mkdirSync(path.join(__dirname, 'logs'), { recursive: true });
        }
        
        // 设置Express
        this.setupExpress();
        
        // 启动时自动恢复监控（可选）
        // this.autoRestartMonitor();
    }
    
    setupExpress() {
        // 静态文件服务
        this.app.use(express.static(path.join(__dirname, 'public')));
        this.app.use(express.json());
        
        // API路由
        this.app.get('/api/status', (req, res) => {
            res.json({
                running: this.isRunning,
                pid: this.pythonProcess ? this.pythonProcess.pid : null,
                restartAttempts: this.restartAttempts,
                timestamp: new Date().toISOString()
            });
        });
        
        this.app.post('/api/start', (req, res) => {
            const result = this.startPythonMonitor();
            if (result.success) {
                res.json({ success: true, message: '监控已启动', pid: this.pythonProcess.pid });
            } else {
                res.json({ success: false, message: result.message });
            }
        });
        
        this.app.post('/api/stop', (req, res) => {
            const result = this.stopPythonMonitor();
            res.json({ success: result.success, message: result.message });
        });
        
        this.app.post('/api/restart', (req, res) => {
            this.stopPythonMonitor();
            setTimeout(() => {
                const result = this.startPythonMonitor();
                res.json({ success: result.success, message: result.message });
            }, 1000);
        });
        
        this.app.get('/api/logs', (req, res) => {
            try {
                const logs = fs.readFileSync(this.logFile, 'utf8');
                const lines = logs.split('\n').filter(line => line.trim());
                // 返回最近100条日志
                const recentLogs = lines.slice(-100);
                res.json({ success: true, logs: recentLogs, total: lines.length });
            } catch (error) {
                res.json({ success: false, logs: [], message: '无法读取日志文件' });
            }
        });
        
        this.app.get('/api/stats', (req, res) => {
            try {
                const stats = {
                    uptime: process.uptime(),
                    memory: process.memoryUsage(),
                    platform: os.platform(),
                    arch: os.arch(),
                    cpus: os.cpus().length,
                    loadavg: os.loadavg()
                };
                res.json({ success: true, stats });
            } catch (error) {
                res.json({ success: false, message: '无法获取系统状态' });
            }
        });
        
        // 清理日志文件
        this.app.post('/api/logs/clear', (req, res) => {
            try {
                fs.writeFileSync(this.logFile, '');
                res.json({ success: true, message: '日志已清空' });
            } catch (error) {
                res.json({ success: false, message: '清空日志失败' });
            }
        });
        
        // 首页
        this.app.get('/', (req, res) => {
            res.sendFile(path.join(__dirname, 'public', 'index.html'));
        });
        
        // 启动服务器
        const PORT = process.env.PORT || 3000;
        this.app.listen(PORT, () => {
            console.log(`✅ 服务器运行在 http://localhost:${PORT}`);
            console.log(`📁 日志文件: ${this.logFile}`);
            console.log('🖨️  自动打印监控系统已就绪');
            
            // 写入启动日志
            this.writeToLog(`[${new Date().toISOString()}] 系统启动，服务器运行在端口 ${PORT}`);
        });
    }
    
    writeToLog(message) {
        try {
            fs.appendFileSync(this.logFile, message + '\n', 'utf8');
        } catch (error) {
            console.error('写入日志失败:', error.message);
        }
    }
    
    startPythonMonitor() {
        if (this.isRunning && this.pythonProcess) {
            return { success: false, message: '监控已经在运行' };
        }
        
        console.log('🚀 启动Python监控进程...');
        this.writeToLog(`[${new Date().toISOString()}] 启动Python监控进程`);
        
        // 创建日志流
        const logStream = fs.createWriteStream(this.logFile, { flags: 'a', encoding: 'utf8' });
        
        try {
            // 启动Python进程，设置UTF-8编码
            const pythonScript = path.join(__dirname, 'python_monitor.py');
            
            // 检查Python脚本是否存在
            if (!fs.existsSync(pythonScript)) {
                const errorMsg = `Python脚本不存在: ${pythonScript}`;
                console.error(`❌ ${errorMsg}`);
                this.writeToLog(`[${new Date().toISOString()}] ERROR: ${errorMsg}`);
                return { success: false, message: errorMsg };
            }
            
            // 设置环境变量，强制使用UTF-8编码
            const env = { ...process.env };
            env.PYTHONIOENCODING = 'utf-8';
            env.PYTHONUTF8 = '1';
            
            this.pythonProcess = spawn('python', [pythonScript], {
                stdio: ['pipe', 'pipe', 'pipe'],
                env: env,
                windowsHide: true
            });
            
            this.isRunning = true;
            this.restartAttempts = 0;
            
            // 设置编码处理
            this.pythonProcess.stdout.setEncoding('utf8');
            this.pythonProcess.stderr.setEncoding('utf8');
            
            // 处理标准输出
            this.pythonProcess.stdout.on('data', (data) => {
                const output = data.toString().trim();
                if (output) {
                    const timestamp = new Date().toISOString();
                    const logMessage = `[${timestamp}] ${output}`;
                    
                    console.log(`📝 ${output}`);
                    logStream.write(logMessage + '\n');
                }
            });
            
            // 处理标准错误
            this.pythonProcess.stderr.on('data', (data) => {
                const error = data.toString().trim();
                if (error) {
                    const timestamp = new Date().toISOString();
                    const logMessage = `[${timestamp}] ERROR: ${error}`;
                    
                    console.error(`❌ ${error}`);
                    logStream.write(logMessage + '\n');
                }
            });
            
            // 处理进程关闭
            this.pythonProcess.on('close', (code, signal) => {
                const timestamp = new Date().toISOString();
                const message = `Python进程退出，代码: ${code}, 信号: ${signal || '无'}`;
                
                console.log(`🛑 ${message}`);
                logStream.write(`[${timestamp}] ${message}\n`);
                
                this.isRunning = false;
                this.pythonProcess = null;
                
                // 如果是意外退出，尝试自动重启
                if (code !== 0 && code !== null) {
                    this.restartAttempts++;
                    
                    if (this.restartAttempts <= this.maxRestartAttempts) {
                        console.log(`🔄 进程意外退出，5秒后尝试重启 (${this.restartAttempts}/${this.maxRestartAttempts})...`);
                        this.writeToLog(`[${timestamp}] 准备重启进程，尝试次数: ${this.restartAttempts}/${this.maxRestartAttempts}`);
                        
                        setTimeout(() => {
                            if (!this.isRunning) {
                                console.log('🔄 正在自动重启监控进程...');
                                this.startPythonMonitor();
                            }
                        }, 5000);
                    } else {
                        console.log('⛔ 达到最大重启次数，停止自动重启');
                        this.writeToLog(`[${timestamp}] 达到最大重启次数 (${this.maxRestartAttempts})，停止自动重启`);
                    }
                } else {
                    // 正常退出，重置重启计数
                    this.restartAttempts = 0;
                }
                
                logStream.end();
            });
            
            // 处理进程错误
            this.pythonProcess.on('error', (err) => {
                const timestamp = new Date().toISOString();
                const errorMsg = `进程启动失败: ${err.message}`;
                
                console.error(`💥 ${errorMsg}`);
                logStream.write(`[${timestamp}] ERROR: ${errorMsg}\n`);
                
                this.isRunning = false;
                this.pythonProcess = null;
                this.restartAttempts++;
                
                logStream.end();
            });
            
            // 监听进程退出前的事件
            process.on('exit', () => {
                if (this.pythonProcess) {
                    this.pythonProcess.kill();
                }
            });
            
            console.log(`✅ Python监控进程已启动，PID: ${this.pythonProcess.pid}`);
            this.writeToLog(`[${new Date().toISOString()}] Python监控进程启动成功，PID: ${this.pythonProcess.pid}`);
            
            return { success: true, message: '监控已启动', pid: this.pythonProcess.pid };
            
        } catch (error) {
            console.error(`💥 启动监控时发生错误: ${error.message}`);
            this.writeToLog(`[${new Date().toISOString()}] ERROR: 启动监控失败 - ${error.message}`);
            
            this.isRunning = false;
            this.pythonProcess = null;
            
            if (logStream && !logStream.closed) {
                logStream.end();
            }
            
            return { success: false, message: `启动失败: ${error.message}` };
        }
    }
    
    stopPythonMonitor() {
        if (this.pythonProcess && this.isRunning) {
            console.log('🛑 停止Python监控进程...');
            this.writeToLog(`[${new Date().toISOString()}] 停止Python监控进程`);
            
            try {
                this.pythonProcess.kill('SIGINT');
                
                // 设置超时，如果进程没有正常退出，强制终止
                setTimeout(() => {
                    if (this.pythonProcess && this.isRunning) {
                        console.log('⚠️  进程未正常退出，强制终止...');
                        this.pythonProcess.kill('SIGTERM');
                    }
                }, 3000);
                
                this.isRunning = false;
                this.restartAttempts = 0;
                
                return { success: true, message: '监控已停止' };
            } catch (error) {
                console.error(`❌ 停止进程失败: ${error.message}`);
                return { success: false, message: `停止失败: ${error.message}` };
            }
        } else {
            return { success: false, message: '监控未运行' };
        }
    }
    
    autoRestartMonitor() {
        // 自动重启逻辑（可选）
        console.log('🔧 启用自动重启监控...');
        
        // 每分钟检查一次，如果进程不运行且重启次数未超限，则重启
        setInterval(() => {
            if (!this.isRunning && this.restartAttempts < this.maxRestartAttempts) {
                console.log('🔧 检测到监控未运行，尝试自动重启...');
                this.startPythonMonitor();
            }
        }, 60000); // 每分钟检查一次
    }
    
    shutdown() {
        console.log('👋 系统正在关闭...');
        this.writeToLog(`[${new Date().toISOString()}] 系统关闭`);
        
        this.stopPythonMonitor();
        
        setTimeout(() => {
            console.log('👋 再见！');
            process.exit(0);
        }, 2000);
    }
}

// 创建并启动管理器
const manager = new PrintMonitorManager();

// 处理退出信号
process.on('SIGINT', () => manager.shutdown());
process.on('SIGTERM', () => manager.shutdown());

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
    console.error('💥 未捕获的异常:', error.message);
    manager.writeToLog(`[${new Date().toISOString()}] UNCAUGHT EXCEPTION: ${error.message}\n${error.stack}`);
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('💥 未处理的Promise拒绝:', reason);
    manager.writeToLog(`[${new Date().toISOString()}] UNHANDLED REJECTION: ${reason}`);
});

// 导出管理器（如果其他模块需要）
module.exports = manager;