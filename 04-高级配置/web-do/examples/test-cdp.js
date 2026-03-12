#!/usr/bin/env node
/**
 * 简单的CDP连接测试
 */

const CDP = require('chrome-remote-interface');

async function testCDP() {
    try {
        console.error('正在连接到浏览器...');

        // 获取所有标签页
        const targets = await CDP.List({});
        console.error(`找到 ${targets.length} 个标签页`);

        // 找到 X 首页
        const homeTab = targets.find(t =>
            t.type === 'page' &&
            t.url.includes('x.com/home')
        );

        if (!homeTab) {
            console.error('未找到 X 首页');
            console.error('可用的标签页:');
            targets.filter(t => t.type === 'page').forEach(t => {
                console.error(`  - ${t.url.substring(0, 60)}`);
            });
            process.exit(1);
        }

        console.error(`找到 X 首页: ${homeTab.url}`);

        // 连接到标签页
        const { Runtime } = await CDP({ target: homeTab });
        console.error('CDP 连接成功');

        // 执行简单的 JavaScript
        const result = await Runtime.evaluate({
            expression: 'document.title',
            returnByValue: true
        });

        console.error('页面标题:', result.result.value);
        console.log(JSON.stringify({ success: true, title: result.result.value }));

        // 不关闭连接
        console.error('完成（标签页保持打开）');

    } catch (error) {
        console.error('错误:', error.message);
        console.error(error.stack);
        process.exit(1);
    }
}

testCDP();
