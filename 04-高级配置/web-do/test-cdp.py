#!/usr/bin/env python3
"""
Web-Do Skill CDP测试脚本
验证CDP连接和数据提取是否正常
"""

import subprocess
import json
import sys

def test_browser_connection():
    """测试1：浏览器CDP连接"""
    print("测试1: 浏览器CDP连接")
    print("-" * 50)

    try:
        # 检查端口
        result = subprocess.run(
            ['curl', '-s', 'http://localhost:9222/json'],
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode != 0:
            print("❌ 失败：无法连接到浏览器（9222端口）")
            print("\n请启动浏览器：")
            print("  start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\\temp\\chrome-debug")
            return False

        tabs = json.loads(result.stdout)

        if not tabs:
            print("❌ 失败：浏览器已启动，但没有打开标签页")
            print("\n请在浏览器中打开一个页面")
            return False

        print(f"✅ 成功：浏览器已启动，找到 {len(tabs)} 个标签页")

        # 显示前3个标签页
        for tab in tabs[:3]:
            url = tab.get('url', 'about:blank')[:60]
            print(f"   - {url}")

        return True

    except Exception as e:
        print(f"❌ 失败: {e}")
        return False

def test_github_trending_tab():
    """测试2：检查GitHub Trending标签页"""
    print("\n测试2: 检查GitHub Trending标签页")
    print("-" * 50)

    try:
        result = subprocess.run(
            ['curl', '-s', 'http://localhost:9222/json'],
            capture_output=True,
            text=True,
            timeout=5
        )

        tabs = json.loads(result.stdout)
        trending_tab = None

        for tab in tabs:
            if 'github.com/trending' in tab.get('url', ''):
                trending_tab = tab
                break

        if not trending_tab:
            print("❌ 失败：未找到GitHub Trending标签页")
            print("\n请在浏览器中打开：https://github.com/trending")
            return False

        print("✅ 成功：找到GitHub Trending标签页")
        print(f"   URL: {trending_tab['url']}")

        return True

    except Exception as e:
        print(f"❌ 失败: {e}")
        return False

def test_data_extraction():
    """测试3：数据提取"""
    print("\n测试3: 数据提取")
    print("-" * 50)

    try:
        # 检查依赖
        import websocket
        print("✅ websocket-client 已安装")
    except ImportError:
        print("❌ 失败：缺少依赖")
        print("\n请安装：")
        print("  pip install websocket-client")
        return False

    try:
        # 运行提取脚本
        result = subprocess.run(
            ['python', 'fetch-github-trending-cdp.py'],
            capture_output=True,
            text=True,
            timeout=30,
            cwd='examples'
        )

        if result.returncode != 0:
            print("❌ 失败：脚本执行出错")
            print(result.stderr)
            return False

        # 验证输出
        try:
            data = json.loads(result.stdout)
        except json.JSONDecodeError:
            print("❌ 失败：输出不是有效的JSON")
            print("\n输出内容：")
            print(result.stdout[:500])
            return False

        if not data:
            print("❌ 失败：提取数据为空")
            return False

        print(f"✅ 成功：提取到 {len(data)} 个项目")
        print(f"✅ 输出大小: {len(result.stdout)} 字符")

        # 显示前3个项目
        print("\n前3个项目:")
        for item in data[:3]:
            print(f"   {item['rank']}. {item['name']} ({item['language']}) - {item['stars']} stars")

        return True

    except Exception as e:
        print(f"❌ 失败: {e}")
        return False

def test_pure_json_output():
    """测试4：验证纯JSON输出"""
    print("\n测试4: 验证纯JSON输出")
    print("-" * 50)

    try:
        result = subprocess.run(
            ['python', 'fetch-github-trending-cdp.py'],
            capture_output=True,
            text=True,
            timeout=30,
            cwd='examples'
        )

        output = result.stdout

        # 检查是否包含非JSON内容
        if output.startswith('错误') or '❌' in output:
            print("❌ 失败：输出包含错误信息")
            return False

        # 验证可以解析为JSON
        json.loads(output)

        print("✅ 成功：输出为纯JSON")
        print("✅ 无日志信息")
        print("✅ 无进度提示")

        return True

    except Exception as e:
        print(f"❌ 失败: {e}")
        return False

def main():
    print("Web-Do Skill CDP测试")
    print("=" * 50)

    results = []

    # 运行所有测试
    results.append(test_browser_connection())
    results.append(test_github_trending_tab())
    results.append(test_data_extraction())
    results.append(test_pure_json_output())

    # 输出总结
    print("\n" + "=" * 50)
    print("测试总结")
    print("=" * 50)

    passed = sum(results)
    total = len(results)

    print(f"通过: {passed}/{total}")

    if passed == total:
        print("\n✅ 所有测试通过！Web-Do Skill 已就绪")
        return 0
    else:
        print("\n❌ 部分测试失败")
        print("\n请检查：")
        print("1. 浏览器是否已启动（9222端口）")
        print("2. 是否已打开 https://github.com/trending")
        print("3. 是否已安装依赖: pip install websocket-client")
        return 1

if __name__ == '__main__':
    sys.exit(main())
