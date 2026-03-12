#!/usr/bin/env python3
"""
OpenClaw集成示例
展示如何在OpenClaw中使用web-do skill
"""

import json
import subprocess

def fetch_data(script_path, *args):
    """
    执行web-do脚本，获取JSON数据

    Args:
        script_path: 脚本路径
        *args: 传递给脚本的参数

    Returns:
        dict: 解析后的JSON数据
    """
    cmd = ['python', script_path] + list(args)

    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=60
    )

    if result.returncode != 0:
        raise Exception(f"脚本执行失败: {result.stderr}")

    return json.loads(result.stdout)

def analyze_with_agent(data):
    """
    将数据传给Agent进行分析

    在OpenClaw中的实际使用：
    sessions_spawn(task=f"分析这些数据：{json.dumps(data)}")
    """
    # 这里只是示例，实际使用时由OpenClaw调用
    print(f"数据已准备好，包含 {len(data)} 个项目")
    print("传给Agent进行分析...")

# 使用示例
if __name__ == '__main__':
    # 1. 执行web-do脚本获取数据
    data = fetch_data('fetch-github-trending.py')

    # 2. 传给Agent分析（在OpenClaw中）
    # sessions_spawn(task=f"分析这些GitHub Trending项目：{json.dumps(data)}")

    print(f"✅ 获取到 {len(data)} 个项目")
    print(f"✅ 数据大小: {len(json.dumps(data))} 字符")
