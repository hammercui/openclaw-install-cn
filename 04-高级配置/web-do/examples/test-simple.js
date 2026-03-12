#!/usr/bin/env node
/**
 * 最简单的CDP测试 - 只获取标签页信息
 */

async function testCDPSimple() {
    try {
        console.error('正在连接到浏览器...');

        const response = await fetch('http://localhost:9222/json');
        const tabs = await response.json();

        console.error(`找到 ${tabs.length} 个标签页\n`);

        const xTabs = tabs.filter(t => t.url.includes('x.com'));

        if (xTabs.length === 0) {
            console.error('未找到 X 标签页');
            console.error('\n可用的标签页:');
            tabs.filter(t => t.type === 'page').forEach(t => {
                console.error(`  - ${t.url.substring(0, 60)}`);
            });
            process.exit(1);
        }

        console.error('找到 X 标签页:');
        xTabs.forEach(tab => {
            console.error(`  - ${tab.url}`);
            console.error(`    标题: ${tab.title}`);
        });

        console.log(JSON.stringify({
            success: true,
            tabs: xTabs.map(t => ({
                url: t.url,
                title: t.title,
                id: t.id
            }))
        }));

        console.error('\n测试完成（浏览器标签页保持打开）');

    } catch (error) {
        console.error('错误:', error.message);
        process.exit(1);
    }
}

testCDPSimple();
