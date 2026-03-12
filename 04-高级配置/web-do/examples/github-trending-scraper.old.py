#!/usr/bin/env python3
"""
GitHub Trending Scraper示例
使用web-scraper skill的最佳实践
"""

import requests
from bs4 import BeautifulSoup
import json
import sys
from datetime import datetime

def main():
    """GitHub Trending抓取示例"""

    # 1. 获取页面（使用HTTP，不启动浏览器）
    url = "https://github.com/trending"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    print(f"🔍 抓取: {url}")
    response = requests.get(url, headers=headers, timeout=30)
    html = response.text

    print(f"✅ HTML获取成功: {len(html)} 字符")

    # 2. 解析页面（不给AI看HTML，只返回JSON）
    soup = BeautifulSoup(html, 'html.parser')
    projects = []

    articles = soup.find_all('article', class_='Box-row')

    for index, article in enumerate(articles, 1):
        # 提取项目信息
        title_tag = article.find('h2', class_='h3 lh-condensed')
        if not title_tag:
            continue

        link = title_tag.find('a')
        href = link.get('href', '')
        name = href.strip('/')

        # 描述
        desc_tag = article.find('p')
        description = desc_tag.get_text(strip=True) if desc_tag else 'No description'

        # 语言
        lang_tag = article.find('span', itemprop='programmingLanguage')
        language = lang_tag.get_text(strip=True) if lang_tag else 'Unknown'

        # Stars
        stars_link = article.find('a', href=lambda x: x and '/stargazers' in x)
        stars = stars_link.get_text(strip=True) if stars_link else '0'

        projects.append({
            'rank': index,
            'name': name,
            'url': f"https://github.com{name}",
            'description': description[:100],
            'language': language,
            'stars': stars
        })

    # 3. 输出JSON（给AI用，不给HTML）
    print(f"\n✅ 提取到 {len(projects)} 个项目\n")
    print("📊 前5个项目：\n")

    for proj in projects[:5]:
        print(f"{proj['rank']}. {proj['name']}")
        print(f"   ⭐ {proj['stars']} | 💻 {proj['language']}")
        print(f"   {proj['description']}\n")

    # 保存JSON
    timestamp = datetime.now().strftime('%Y-%m-%d')
    filename = f"trending-{timestamp}.json"

    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(projects, f, indent=2, ensure_ascii=False)

    print(f"💾 已保存: {filename}")
    print(f"\n📊 Token节省对比：")
    print(f"   ❌ 把HTML给AI: ~50,000 tokens")
    print(f"   ✅ 只给JSON:   ~{len(json.dumps(projects))} tokens")
    print(f"   💰 节省:      99%")

if __name__ == '__main__':
    main()
