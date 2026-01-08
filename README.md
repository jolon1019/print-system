# 热卷打印管理系统

一个集成的Windows桌面应用程序，用于管理热卷打印服务。

## 功能特性

- **统一界面**: 将三个独立的服务集成到一个窗口中
- **服务管理**: 可以独立启动、停止每个服务
- **实时监控**: 查看服务状态和运行日志
- **现代化UI**: 使用Electron构建的现代化用户界面

## 集成的服务

1. **打印服务器 (print-server.js)**
   - WebSocket服务器，监听端口 17026
   - HTTP API服务器，监听端口 17027
   - 功能：接收打印任务、管理打印机状态、处理模板打印

2. **打印机客户端 (printer-client.js)**
   - 连接到打印服务器 (127.0.0.1:17026)
   - 功能：接收打印任务、调用系统打印

3. **Python监控 (python_monitor.py)**
   - 监控打印窗口
   - 自动点击打印按钮
   - 功能：查找打印窗口、自动执行打印操作、监控打印状态

## 安装和运行

### 前置要求

- Node.js (建议版本 16.x 或更高)
- Python 3.x (用于运行 python_monitor.py)
- npm (随 Node.js 一起安装)

### 安装步骤

1. 将以下文件复制到 `electron-app` 目录：
   - `print-server.js`
   - `printer-client.js`
   - `python_monitor.py`

2. 双击运行 `start.bat` 文件

或者使用命令行：

```bash
cd electron-app
npm install
npm start
```

## 使用说明

### 启动服务

1. 打开应用程序后，你会看到三个服务的卡片
2. 点击每个服务的"启动"按钮来启动对应的服务
3. 服务状态会实时更新

### 查看日志

1. 点击左侧菜单的"日志查看"
2. 可以选择查看特定服务的日志或全部日志
3. 日志会实时更新显示

### 停止服务

1. 在仪表盘或服务管理页面
2. 点击对应服务的"停止"按钮
3. 服务会安全停止

## 界面说明

### 仪表盘
- 显示三个服务的状态和控制按钮
- 显示系统信息（操作系统、Node.js版本、Electron版本、运行时间）

### 服务管理
- 详细显示每个服务的描述和功能
- 提供启动/停止控制按钮

### 日志查看
- 实时显示所有服务的日志输出
- 支持按服务过滤日志
- 可以清空日志

## 技术栈

- **Electron**: 跨平台桌面应用框架
- **Node.js**: 后端运行时环境
- **WebSocket**: 服务间通信
- **Python**: 自动化监控脚本

## 文件结构

```
electron-app/
├── main.js           # Electron主进程
├── index.html        # 主界面HTML
├── styles.css        # 样式文件
├── renderer.js       # 渲染进程JavaScript
├── package.json      # 项目配置
├── start.bat         # Windows启动脚本
├── print-server.js   # 打印服务器（需复制）
├── printer-client.js # 打印机客户端（需复制）
└── python_monitor.py # Python监控脚本（需复制）
```

## 注意事项

1. 确保所有服务文件（`print-server.js`、`printer-client.js`、`python_monitor.py`）都已复制到 `electron-app` 目录
2. Python需要添加到系统PATH环境变量中
3. 首次运行时会自动安装依赖，需要网络连接
4. 建议按以下顺序启动服务：
   - 先启动打印服务器
   - 再启动打印机客户端
   - 最后启动Python监控

## 故障排除

### 服务无法启动
- 检查端口是否被占用（17026, 17027）
- 检查Python是否正确安装
- 查看日志页面获取详细错误信息

### Python监控无法运行
- 确保Python已安装并添加到PATH
- 检查Python依赖库是否已安装（pywin32等）
- 以管理员权限运行应用程序

## 开发和构建

### 开发模式
```bash
npm run dev
```

### 构建Windows安装包
```bash
npm run build-win
```

构建完成后，安装包会在 `dist` 目录中。

## 许可证

MIT License
