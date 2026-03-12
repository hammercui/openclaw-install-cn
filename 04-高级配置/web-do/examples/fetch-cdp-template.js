#!/usr/bin/env node
/**
 * CDP数据提取模板
 * 只负责：从浏览器获取数据 → 清洗 → 输出JSON
 * 不做：总结、分析、格式化输出
 */

const CDP = require('chrome-remote-interface');

async function fetchViaCDP(targetUrl) {
    try {
        // 获取所有标签页
        const targets = await CDP.List({});

        // 找到匹配的标签页
        const target = targets.find(t => t.url.includes(targetUrl));

        if (!target) {
            console.error('错误：未找到目标标签页');
            console.error('请在浏览器中打开页面后重试');
            process.exit(1);
        }

        // 连接到目标标签页
        const { Runtime } = await CDP({ target });

        // 执行JavaScript提取数据
        const result = await Runtime.evaluate({
            expression: `
                (function() {
                    // 在这里编写提取逻辑
                    const items = [];

                    // 示例：提取文章列表
                    document.querySelectorAll('article').forEach((article, index) => {
                        const title = article.querySelector('h2')?.textContent.trim();
                        const url = article.querySelector('a')?.href;
                        const desc = article.querySelector('p')?.textContent.trim();

                        if (title) {
                            items.push({
                                rank: index + 1,
                                title,
                                url,
                                description: desc
                            });
                        }
                    });

                    return items;
                })();
            `,
            returnByValue: true
        });

        // 只输出纯JSON，不输出任何其他信息
        console.log(JSON.stringify(result.result.value, null, 2));

        // 不关闭 CDP 连接，让浏览器标签页保持打开
        // CDP 连接会自动释放

    } catch (error) {
        console.error('错误：', error.message);
        process.exit(1);
    }
}

// 从命令行参数获取目标URL
const targetUrl = process.argv[2] || 'github.com';

fetchViaCDP(targetUrl);
