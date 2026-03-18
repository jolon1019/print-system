"""
增强坐标点击版本 - 带验证和备选方案
优化版本: 增加窗口检测稳定性、重试机制、错误处理
"""
import sys
import time
import pyautogui
import pygetwindow as gw
from datetime import datetime
import traceback

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.1

CONFIG = {
    'scan_interval': 0.5,
    'window_check_interval': 0.2,
    'max_retry_count': 3,
    'retry_delay': 0.5,
    'activation_timeout': 2.0,
    
    'keywords': [
        '打印窗口',
        '打印',
        'Print',
        '打印机',
        'Print Dialog',
        'Microsoft Print',
        '打印对话框',
    ],
    
    'strict_keywords': [
        '打印窗口',
        '打印对话框',
        'Print Dialog',
    ],
    
    'exclude_keywords': [
        '设置',
        'Settings',
        '偏好设置',
        '帮助',
        'Help',
        '关于',
        'About',
        '属性',
        'Properties',
        '选项',
        'Options',
        '配置',
        'Configuration',
        '记事本',
        'Notepad',
        'Word',
        'Excel',
        'PowerPoint',
        '浏览器',
        'Browser',
        'Chrome',
        'Edge',
        'Firefox',
        'print-system',
        'print system',
        'printsystem',
        'Trae CN',
        'Visual Studio',
        'VS Code',
        'Code',
        'Terminal',
        'PowerShell',
        'Command Prompt',
        'cmd',
        'npm',
        'node',
        'python',
        'hexin',
        '同花顺',
        'OpenClaw',
        'WPS Office',
        'Administrator',
        'Program Manager',
        'Text Input',
        'Application',
    ],
    
    'primary_coordinates': (1482, 903),
    
    'backup_positions': [
        {'type': 'absolute', 'x': 1482, 'y': 903},
        {'type': 'relative', 'x': 0.95, 'y': 0.95},
        {'type': 'relative', 'x': 0.90, 'y': 0.90},
        {'type': 'relative', 'x': 0.85, 'y': 0.85},
        {'type': 'relative', 'x': 0.80, 'y': 0.90},
        {'type': 'enter_key'},
        {'type': 'alt_p'},
        {'type': 'ctrl_p'},
    ],
    
    'click_verification_delay': 0.3,
    
    'debug_mode': True,
}

def log_message(message, level='INFO'):
    """安全输出日志"""
    timestamp = datetime.now().strftime('%H:%M:%S.%f')[:-3]
    print(f"[{timestamp}] [{level}] {message}")
    sys.stdout.flush()

def verify_coordinates(x, y):
    """验证坐标是否在屏幕范围内"""
    try:
        screen_width, screen_height = pyautogui.size()
        
        if 0 <= x < screen_width and 0 <= y < screen_height:
            log_message(f"坐标验证通过: ({x}, {y})", 'DEBUG')
            return True
        else:
            log_message(f"坐标无效: ({x}, {y}) 超出屏幕范围 {screen_width}x{screen_height}", 'WARN')
            return False
    except Exception as e:
        log_message(f"坐标验证失败: {e}", 'ERROR')
        return False

def is_valid_print_window(title):
    """检查窗口标题是否为有效的打印窗口 - 严格模式"""
    if not title or not title.strip():
        return False
    
    title_lower = title.lower()
    title_stripped = title.strip()
    
    if CONFIG['debug_mode']:
        log_message(f"检查窗口标题: '{title_stripped}'", 'DEBUG')
    
    for exclude in CONFIG['exclude_keywords']:
        if exclude.lower() in title_lower:
            if CONFIG['debug_mode']:
                log_message(f"  ❌ 排除: 包含关键词 '{exclude}'", 'DEBUG')
            return False
    
    has_strict_keyword = False
    has_normal_keyword = False
    
    for keyword in CONFIG['strict_keywords']:
        if keyword.lower() in title_lower:
            has_strict_keyword = True
            if CONFIG['debug_mode']:
                log_message(f"  ✅ 匹配严格关键词: '{keyword}'", 'DEBUG')
            break
    
    if not has_strict_keyword:
        for keyword in CONFIG['keywords']:
            if keyword.lower() in title_lower:
                has_normal_keyword = True
                if CONFIG['debug_mode']:
                    log_message(f"  ⚠️ 匹配普通关键词: '{keyword}'", 'DEBUG')
                break
    
    if not has_strict_keyword and not has_normal_keyword:
        if CONFIG['debug_mode']:
            log_message(f"  ❌ 不匹配任何关键词", 'DEBUG')
        return False
    
    if not has_strict_keyword and has_normal_keyword:
        if CONFIG['debug_mode']:
            log_message(f"  ⚠️ 警告: 仅匹配普通关键词，可能误识别", 'DEBUG')
    
    return True

def check_window_characteristics(window):
    """检查窗口特征 - 简化版，打印窗口默认全屏"""
    try:
        title = window.title
        visible = window.visible
        minimized = window.isMinimized
        
        if CONFIG['debug_mode']:
            log_message(f"窗口特征: '{title}' 可见={visible} 最小化={minimized}", 'DEBUG')
        
        if not visible:
            if CONFIG['debug_mode']:
                log_message(f"  ❌ 窗口不可见", 'DEBUG')
            return False
        
        if minimized:
            if CONFIG['debug_mode']:
                log_message(f"  ❌ 窗口已最小化", 'DEBUG')
            return False
        
        if CONFIG['debug_mode']:
            log_message(f"  ✅ 窗口特征验证通过", 'DEBUG')
        
        return True
        
    except Exception as e:
        log_message(f"窗口特征检查失败: {e}", 'ERROR')
        return False

def find_print_windows_enhanced():
    """增强版窗口查找 - 带重试机制和严格验证"""
    windows = []
    
    for attempt in range(CONFIG['max_retry_count']):
        try:
            all_windows = gw.getAllWindows()
            
            if CONFIG['debug_mode'] and attempt == 0:
                log_message(f"扫描系统窗口，共 {len(all_windows)} 个", 'DEBUG')
            
            for window in all_windows:
                title = window.title
                
                if not is_valid_print_window(title):
                    continue
                
                if not check_window_characteristics(window):
                    continue
                
                try:
                    windows.append({
                        'title': title,
                        'window': window,
                        'left': window.left,
                        'top': window.top,
                        'width': window.width,
                        'height': window.height,
                        'is_active': window.isActive,
                    })
                    
                    if CONFIG['debug_mode']:
                        log_message(f"  ✅ 添加窗口: '{title}' 位置=({window.left}, {window.top})", 'DEBUG')
                        
                except Exception as e:
                    log_message(f"窗口信息获取失败: {title} - {e}", 'WARN')
                    continue
            
            if windows:
                log_message(f"找到 {len(windows)} 个有效打印窗口", 'INFO')
                return windows
            elif CONFIG['debug_mode'] and attempt == 0:
                log_message("未找到任何打印窗口", 'DEBUG')
                
        except Exception as e:
            log_message(f"查找窗口错误 (尝试 {attempt + 1}/{CONFIG['max_retry_count']}): {e}", 'ERROR')
            time.sleep(CONFIG['retry_delay'])
    
    return windows

def calculate_backup_position(win_info, position_config):
    """计算备用坐标位置"""
    try:
        if position_config['type'] == 'absolute':
            return (position_config['x'], position_config['y'])
        
        elif position_config['type'] == 'relative':
            rel_x = position_config['x']
            rel_y = position_config['y']
            
            x = win_info['left'] + int(win_info['width'] * rel_x)
            y = win_info['top'] + int(win_info['height'] * rel_y)
            
            return (x, y)
        
    except Exception as e:
        log_message(f"计算备用位置失败: {e}", 'ERROR')
    
    return None

def activate_window_with_retry(win_info):
    """带重试的窗口激活"""
    window = win_info['window']
    title = win_info['title']
    
    for attempt in range(CONFIG['max_retry_count']):
        try:
            if window.isMinimized:
                window.restore()
                time.sleep(0.2)
            
            window.activate()
            time.sleep(0.3)
            
            if window.isActive:
                log_message(f"窗口激活成功 (尝试 {attempt + 1}): {title}", 'INFO')
                return True
            else:
                log_message(f"窗口激活验证失败 (尝试 {attempt + 1})", 'WARN')
                
        except Exception as e:
            log_message(f"窗口激活异常 (尝试 {attempt + 1}): {e}", 'WARN')
        
        time.sleep(CONFIG['retry_delay'])
    
    log_message(f"窗口激活失败，使用备用方案", 'WARN')
    return False

def execute_print_with_backups(win_info):
    """使用多种方法执行打印 - 带完整验证"""
    title = win_info['title']
    
    log_message(f"开始处理打印窗口: {title}", 'INFO')
    
    if not activate_window_with_retry(win_info):
        log_message("窗口激活失败，继续尝试打印操作", 'WARN')
    
    for i, position_config in enumerate(CONFIG['backup_positions']):
        try:
            log_message(f"尝试方法 {i+1}/{len(CONFIG['backup_positions'])}: {position_config['type']}", 'INFO')
            
            if position_config['type'] in ['absolute', 'relative']:
                coords = calculate_backup_position(win_info, position_config)
                if not coords:
                    continue
                
                x, y = coords
                
                if not verify_coordinates(x, y):
                    continue
                
                pyautogui.moveTo(x, y, duration=0.05)
                time.sleep(0.05)
                pyautogui.click(x, y)
                time.sleep(CONFIG['click_verification_delay'])
                
                if not window_exists(title):
                    log_message(f"✅ 方法 {i+1} 成功: {position_config['type']} @ ({x}, {y})", 'INFO')
                    return True
                else:
                    log_message(f"方法 {i+1} 未生效，窗口仍存在", 'DEBUG')
            
            elif position_config['type'] == 'enter_key':
                pyautogui.press('enter')
                time.sleep(CONFIG['click_verification_delay'])
                if not window_exists(title):
                    log_message("✅ 方法成功: 回车键", 'INFO')
                    return True
            
            elif position_config['type'] == 'alt_p':
                pyautogui.hotkey('alt', 'p')
                time.sleep(CONFIG['click_verification_delay'])
                if not window_exists(title):
                    log_message("✅ 方法成功: Alt+P", 'INFO')
                    return True
            
            elif position_config['type'] == 'ctrl_p':
                pyautogui.hotkey('ctrl', 'p')
                time.sleep(CONFIG['click_verification_delay'])
                if not window_exists(title):
                    log_message("✅ 方法成功: Ctrl+P", 'INFO')
                    return True
            
            time.sleep(0.1)
            
        except Exception as e:
            log_message(f"方法 {i+1} 执行失败: {e}", 'ERROR')
            continue
    
    log_message("❌ 所有打印方法都失败", 'ERROR')
    return False

def window_exists(title):
    """检查窗口是否还存在"""
    try:
        windows = gw.getWindowsWithTitle(title)
        return len(windows) > 0 and any(w.visible for w in windows)
    except:
        return False

def list_all_windows():
    """列出所有窗口 - 用于调试"""
    try:
        all_windows = gw.getAllWindows()
        log_message("=" * 60, 'DEBUG')
        log_message(f"系统窗口列表 (共 {len(all_windows)} 个)", 'DEBUG')
        log_message("=" * 60, 'DEBUG')
        
        for i, window in enumerate(all_windows, 1):
            title = window.title if window.title else "(无标题)"
            visible = "可见" if window.visible else "隐藏"
            minimized = "最小化" if window.isMinimized else "正常"
            size = f"{window.width}x{window.height}"
            
            log_message(f"{i:3d}. [{visible}] [{minimized}] {size:8s} - {title}", 'DEBUG')
        
        log_message("=" * 60, 'DEBUG')
        
    except Exception as e:
        log_message(f"列出窗口失败: {e}", 'ERROR')

def main():
    """主监控循环 - 只检查新弹出的窗口"""
    log_message("=" * 60, 'INFO')
    log_message("增强坐标点击版自动打印监控 - 优化版", 'INFO')
    log_message(f"主要坐标: {CONFIG['primary_coordinates']}", 'INFO')
    log_message(f"备用方案: {len(CONFIG['backup_positions'])} 种", 'INFO')
    log_message(f"扫描间隔: {CONFIG['scan_interval']} 秒", 'INFO')
    log_message(f"最大重试次数: {CONFIG['max_retry_count']}", 'INFO')
    log_message(f"调试模式: {'开启' if CONFIG['debug_mode'] else '关闭'}", 'INFO')
    log_message("=" * 60, 'INFO')
    
    if CONFIG['debug_mode']:
        list_all_windows()
    
    known_windows = set()
    processed_windows = {}
    consecutive_errors = 0
    max_consecutive_errors = 10
    
    try:
        log_message("初始化：记录当前所有窗口...", 'INFO')
        all_windows = gw.getAllWindows()
        for window in all_windows:
            if window.title:
                known_windows.add(window.title)
        log_message(f"已记录 {len(known_windows)} 个已知窗口", 'INFO')
        
        while True:
            try:
                current_time = time.time()
                
                all_windows = gw.getAllWindows()
                current_window_titles = {w.title for w in all_windows if w.title}
                
                new_windows = current_window_titles - known_windows
                closed_windows = known_windows - current_window_titles
                
                if new_windows:
                    log_message(f"发现 {len(new_windows)} 个新窗口", 'DEBUG')
                
                if closed_windows:
                    log_message(f"关闭 {len(closed_windows)} 个窗口", 'DEBUG')
                    for title in closed_windows:
                        if title in processed_windows:
                            del processed_windows[title]
                            log_message(f"窗口已关闭: {title}", 'DEBUG')
                
                for title in new_windows:
                    if is_valid_print_window(title):
                        try:
                            windows = gw.getWindowsWithTitle(title)
                            for window in windows:
                                if not window.visible or window.isMinimized:
                                    continue
                                
                                if not check_window_characteristics(window):
                                    continue
                                
                                win_info = {
                                    'title': title,
                                    'window': window,
                                    'left': window.left,
                                    'top': window.top,
                                    'width': window.width,
                                    'height': window.height,
                                    'is_active': window.isActive,
                                }
                                
                                log_message(f"检测到新打印窗口: {title}", 'INFO')
                                log_message(f"  窗口位置: ({win_info['left']}, {win_info['top']})", 'INFO')
                                log_message(f"  窗口大小: {win_info['width']}x{win_info['height']}", 'INFO')
                                log_message(f"  窗口状态: {'活动' if win_info.get('is_active') else '非活动'}", 'INFO')
                                
                                if execute_print_with_backups(win_info):
                                    processed_windows[title] = current_time
                                    log_message(f"✅ 打印成功: {title}", 'INFO')
                                else:
                                    log_message(f"❌ 打印失败: {title}", 'ERROR')
                                    processed_windows[title] = current_time
                                break
                        except Exception as e:
                            log_message(f"处理窗口失败: {title} - {e}", 'ERROR')
                    else:
                        if CONFIG['debug_mode']:
                            log_message(f"新窗口不是打印窗口: {title}", 'DEBUG')
                
                known_windows = current_window_titles
                
                consecutive_errors = 0
                
                time.sleep(CONFIG['scan_interval'])
                
            except Exception as e:
                consecutive_errors += 1
                log_message(f"循环错误 ({consecutive_errors}/{max_consecutive_errors}): {e}", 'ERROR')
                log_message(traceback.format_exc(), 'DEBUG')
                
                if consecutive_errors >= max_consecutive_errors:
                    log_message("连续错误过多，等待30秒后重试...", 'ERROR')
                    time.sleep(30)
                    consecutive_errors = 0
                else:
                    time.sleep(CONFIG['retry_delay'])
                
    except KeyboardInterrupt:
        log_message("监控已停止 (用户中断)", 'INFO')
    except Exception as e:
        log_message(f"运行错误: {e}", 'ERROR')
        log_message(traceback.format_exc(), 'ERROR')

if __name__ == "__main__":
    main()