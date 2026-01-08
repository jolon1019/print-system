"""
增强坐标点击版本 - 带验证和备选方案
"""
import sys
import time
import pyautogui
import pygetwindow as gw
from datetime import datetime

# 强制UTF-8编码
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

# 配置 - 您的坐标和备选方案
CONFIG = {
    'scan_interval': 1.0,
    'keywords': ['打印窗口'],
    
    # 主要坐标 (您的坐标)
    'primary_coordinates': (1482, 903),
    
    # 备用坐标 (相对位置，如果主要坐标失效)
    'backup_positions': [
        {'type': 'absolute', 'x': 1482, 'y': 903},  # 您的原始坐标
        {'type': 'relative', 'x': 0.95, 'y': 0.95},  # 右下角 (95%, 95%)
        {'type': 'relative', 'x': 0.90, 'y': 0.90},  # 右下角 (90%, 90%)
        {'type': 'enter_key'},  # 按回车键
        {'type': 'alt_p'},      # 按Alt+P
    ],
}

def log_message(message):
    """安全输出日志"""
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"[{timestamp}] {message}")
    sys.stdout.flush()

def verify_coordinates(x, y):
    """验证坐标是否在屏幕范围内"""
    try:
        screen_width, screen_height = pyautogui.size()
        
        if 0 <= x < screen_width and 0 <= y < screen_height:
            log_message(f"坐标验证通过: ({x}, {y}) 在屏幕范围内")
            return True
        else:
            log_message(f"坐标无效: ({x}, {y}) 超出屏幕范围 {screen_width}x{screen_height}")
            return False
    except Exception as e:
        log_message(f"坐标验证失败: {e}")
        return False

def find_print_windows_enhanced():
    """增强版窗口查找"""
    windows = []
    
    try:
        # 获取所有窗口
        all_windows = gw.getAllWindows()
        
        for window in all_windows:
            title = window.title
            if not title or not title.strip():
                continue
            
            # 检查是否为打印窗口
            is_print_window = False
            for keyword in CONFIG['keywords']:
                if keyword in title:
                    is_print_window = True
                    break
            
            if is_print_window:
                # 检查窗口是否可见且足够大
                if (window.visible and window.width > 200 and window.height > 150):
                    windows.append({
                        'title': title,
                        'window': window,
                        'left': window.left,
                        'top': window.top,
                        'width': window.width,
                        'height': window.height
                    })
        
        return windows
        
    except Exception as e:
        log_message(f"查找窗口错误: {e}")
        return []

def calculate_backup_position(win_info, position_config):
    """计算备用坐标位置"""
    try:
        if position_config['type'] == 'absolute':
            return (position_config['x'], position_config['y'])
        
        elif position_config['type'] == 'relative':
            # 相对坐标: 基于窗口位置计算
            rel_x = position_config['x']  # 0.0-1.0
            rel_y = position_config['y']  # 0.0-1.0
            
            # 计算绝对坐标
            x = win_info['left'] + int(win_info['width'] * rel_x)
            y = win_info['top'] + int(win_info['height'] * rel_y)
            
            return (x, y)
        
    except Exception as e:
        log_message(f"计算备用位置失败: {e}")
    
    return None

def execute_print_with_backups(win_info):
    """使用多种方法执行打印"""
    title = win_info['title']
    
    log_message(f"开始处理打印窗口: {title}")
    
    # 首先激活窗口
    try:
        window = win_info['window']
        if window.isMinimized:
            window.restore()
        window.activate()
        time.sleep(0.5)
        log_message("窗口激活成功")
    except Exception as e:
        log_message(f"窗口激活失败: {e}")
    
    # 尝试所有打印方法
    for i, position_config in enumerate(CONFIG['backup_positions']):
        try:
            log_message(f"尝试方法 {i+1}: {position_config['type']}")
            
            if position_config['type'] in ['absolute', 'relative']:
                # 坐标点击方法
                coords = calculate_backup_position(win_info, position_config)
                if coords:
                    x, y = coords
                    
                    # 验证坐标
                    if verify_coordinates(x, y):
                        # 移动并点击
                        pyautogui.moveTo(x, y, duration=0.1)
                        time.sleep(0.05)
                        pyautogui.click(x, y)
                        time.sleep(0.5)
                        
                        # 检查窗口是否还存在
                        if not window_exists(title):
                            log_message(f"方法 {i+1} 成功: {position_config['type']}")
                            return True
                    else:
                        log_message(f"坐标无效，跳过: {coords}")
            
            elif position_config['type'] == 'enter_key':
                # 按回车键
                pyautogui.press('enter')
                time.sleep(0.5)
                if not window_exists(title):
                    log_message("方法成功: 回车键")
                    return True
            
            elif position_config['type'] == 'alt_p':
                # 按Alt+P
                pyautogui.hotkey('alt', 'p')
                time.sleep(0.5)
                if not window_exists(title):
                    log_message("方法成功: Alt+P")
                    return True
            
            # 方法之间稍作延迟
            time.sleep(0.2)
            
        except Exception as e:
            log_message(f"方法 {i+1} 执行失败: {e}")
    
    log_message("所有打印方法都失败")
    return False

def window_exists(title):
    """检查窗口是否还存在"""
    try:
        windows = gw.getWindowsWithTitle(title)
        return len(windows) > 0
    except:
        return False

def main():
    """主监控循环"""
    log_message("=" * 60)
    log_message("增强坐标点击版自动打印监控")
    log_message(f"主要坐标: {CONFIG['primary_coordinates']}")
    log_message(f"备用方案: {len(CONFIG['backup_positions'])} 种")
    log_message("=" * 60)
    
    processed_windows = set()
    
    try:
        while True:
            # 查找打印窗口
            print_windows = find_print_windows_enhanced()
            
            if print_windows:
                log_message(f"当前有 {len(print_windows)} 个打印窗口")
            
            # 处理新窗口
            for win_info in print_windows:
                title = win_info['title']
                
                if title not in processed_windows:
                    log_message(f"检测到新打印窗口: {title}")
                    log_message(f"  窗口位置: ({win_info['left']}, {win_info['top']})")
                    log_message(f"  窗口大小: {win_info['width']}x{win_info['height']}")
                    
                    # 执行打印
                    if execute_print_with_backups(win_info):
                        processed_windows.add(title)
                        log_message(f"✅ 打印成功: {title}")
                    else:
                        log_message(f"❌ 打印失败: {title}")
            
            # 清理已关闭的窗口
            current_titles = {info['title'] for info in find_print_windows_enhanced()}
            processed_windows = {title for title in processed_windows if title in current_titles}
            
            # 休眠
            time.sleep(CONFIG['scan_interval'])
            
    except KeyboardInterrupt:
        log_message("监控已停止")
    except Exception as e:
        log_message(f"运行错误: {e}")

if __name__ == "__main__":
    main()