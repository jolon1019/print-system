"""
窗口检测测试脚本 - 用于诊断打印窗口识别问题
运行此脚本可以查看所有窗口及其匹配状态
"""
import sys
import pygetwindow as gw

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

CONFIG = {
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
}

def is_valid_print_window(title):
    """检查窗口标题是否为有效的打印窗口"""
    if not title or not title.strip():
        return False
    
    title_lower = title.lower()
    
    for exclude in CONFIG['exclude_keywords']:
        if exclude.lower() in title_lower:
            return False
    
    for keyword in CONFIG['strict_keywords']:
        if keyword.lower() in title_lower:
            return True
    
    for keyword in CONFIG['keywords']:
        if keyword.lower() in title_lower:
            return True
    
    return False

def main():
    print("=" * 80)
    print("窗口检测诊断工具")
    print("=" * 80)
    
    try:
        all_windows = gw.getAllWindows()
        print(f"\n系统中共有 {len(all_windows)} 个窗口\n")
        
        print("=" * 80)
        print("所有窗口列表:")
        print("=" * 80)
        
        matched_windows = []
        
        for i, window in enumerate(all_windows, 1):
            try:
                title = window.title if window.title else "(无标题)"
                visible = "可见" if window.visible else "隐藏"
                minimized = "最小化" if window.isMinimized else "正常"
                size = f"{window.width:4d}x{window.height:4d}"
                position = f"({window.left:4d}, {window.top:4d})"
                
                is_match = is_valid_print_window(title)
                match_status = "✅ 匹配" if is_match else "❌ 不匹配"
                
                print(f"{i:3d}. {match_status} [{visible}] [{minimized}] {size} {position} - {title}")
                
                if is_match:
                    matched_windows.append(window)
            except Exception as e:
                print(f"{i:3d}. ⚠️ 窗口信息获取失败: {e}")
                continue
        
        print("=" * 80)
        print(f"\n匹配结果: 找到 {len(matched_windows)} 个可能的打印窗口\n")
        
        if matched_windows:
            print("=" * 80)
            print("匹配的窗口详情:")
            print("=" * 80)
            
            for i, window in enumerate(matched_windows, 1):
                try:
                    title = window.title
                    print(f"\n{i}. 窗口标题: {title}")
                    print(f"   大小: {window.width}x{window.height}")
                    print(f"   位置: ({window.left}, {window.top})")
                    print(f"   可见: {window.visible}")
                    print(f"   最小化: {window.isMinimized}")
                    print(f"   活动: {window.isActive}")
                except Exception as e:
                    print(f"\n{i}. 窗口信息获取失败: {e}")
        else:
            print("提示: 如果没有找到打印窗口，请检查:")
            print("  1. 是否真的打开了打印对话框")
            print("  2. 打印对话框的标题是否包含 '打印' 或 'Print' 关键词")
            print("  3. 打印对话框是否可见（没有被最小化）")
            print("\n如果打印窗口标题不匹配，可以修改 CONFIG 中的 keywords")
        
        print("\n" + "=" * 80)
        
    except Exception as e:
        print(f"\n错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
