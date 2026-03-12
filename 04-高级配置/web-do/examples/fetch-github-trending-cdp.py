#!/usr/bin/env python3
"""
GitHub Trending CDP数据提取
使用CDP连接到浏览器（9222端口）
只负责：提取数据 → 清洗 → 输出JSON
"""

import subprocess
import json
import sys

def get_browser_tabs():
    """获取所有浏览器标签页"""
    try:
        result = subprocess.run(
            ['curl', '-s', 'http://localhost:9222/json'],
            capture_output=True,
            text=True,
            timeout=5
        )
        return json.loads(result.stdout)
    except Exception as e:
        print(f"错误：无法连接到浏览器（9222端口）")
        print(f"请确保浏览器已启动：")
        print(f'  start msedge.exe --remote-debugging-port=9222 --user-data-dir=D:\\temp\\chrome-debug')
        sys.exit(1)

def find_tab(tabs, url_keyword):
    """找到包含指定关键词的标签页"""
    for tab in tabs:
        if url_keyword in tab.get('url', ''):
            return tab
    return None

def fetch_github_trending():
    """获取GitHub Trending数据"""

    # 1. 获取所有标签页
    tabs = get_browser_tabs()

    # 2. 查找GitHub Trending标签页
    trending_tab = find_tab(tabs, 'github.com/trending')

    if not trending_tab:
        print("错误：未找到GitHub Trending标签页")
        print("请在浏览器中打开：https://github.com/trending")
        sys.exit(1)

    # 3. 连接到CDP WebSocket
    import websocket
    ws_url = trending_tab['webSocketDebuggerUrl']
    ws = websocket.create_connection(ws_url)

    try:
        # 启用Runtime
        ws.send(json.dumps({
            'id': 1,
            'method': 'Runtime.enable',
            'params': {}
        }))
        ws.recv()  # 接收响应

        # 执行JavaScript提取数据
        ws.send(json.dumps({
            'id': 2,
            'method': 'Runtime.evaluate',
            'params': {
                'expression': '''
                    (function() {
                        const items = [];
                        const articles = document.querySelectorAll('article.Box-row');

                        articles.forEach((article, index) => {
                            const titleTag = article.querySelector('h2.h3.lh-condensed');
                            if (!titleTag) return;

                            const link = titleTag.querySelector('a');
                            const href = link?.getAttribute('href') || '';
                            const name = href.replace(/^\\//, '');

                            const descTag = article.querySelector('p');
                            const description = descTag?.textContent.trim() || '';

                            const langTag = article.querySelector('span[itemprop="programmingLanguage"]');
                            const language = langTag?.textContent.trim() || '';

                            const starsLink = article.querySelector('a[href*="/stargazers"]');
                            const stars = starsLink?.textContent.trim() || '0';

                            const forksLink = article.querySelector('a[href*="/forks"]');
                            const forks = forksLink?.textContent.trim() || '0';

                            const todayStarsSpan = Array.from(article.querySelectorAll('span'))
                                .find(s => s.textContent.includes('stars today'));
                            const todayStars = todayStarsSpan?.textContent.trim() || '0';

                            items.push({
                                rank: index + 1,
                                name: name,
                                url: `https://github.com/${name}`,
                                description: description,
                                language: language,
                                stars: stars,
                                forks: forks,
                                todayStars: todayStars
                            });
                        });

                        return items;
                    })();
                ''',
                'returnByValue': True,
                'awaitPromise': True
            }
        }))

        # 接收响应
        response = ws.recv()
        result = json.loads(response)

        # 提取数据
        data = result['result']['result']['value']

        # 输出纯JSON（不输出任何其他信息）
        print(json.dumps(data, ensure_ascii=False, indent=2))

        # 不关闭 WebSocket 连接，让浏览器标签页保持打开
        # 连接会自动释放

if __name__ == '__main__':
    fetch_github_trending()
