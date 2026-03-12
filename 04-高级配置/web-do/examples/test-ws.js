#!/usr/bin/env node
/**
 * 直接测试WebSocket连接
 */

const WebSocket = require('ws');

async function testWebSocket() {
    try {
        console.error('正在获取标签页列表...');

        const response = await fetch('http://localhost:9222/json');
        const tabs = await response.json();

        console.error(`找到 ${tabs.length} 个标签页`);

        const homeTab = tabs.find(t =>
            t.type === 'page' &&
            t.url.includes('x.com/home')
        );

        if (!homeTab) {
            console.error('未找到 X 首页');
            process.exit(1);
        }

        console.error(`找到 X 首页: ${homeTab.url}`);
        console.error(`WebSocket URL: ${homeTab.webSocketDebuggerUrl}`);

        console.error('正在连接 WebSocket...');
        const ws = new WebSocket(homeTab.webSocketDebuggerUrl);

        ws.on('open', () => {
            console.error('WebSocket 连接成功');

            // 发送 Runtime.evaluate 命令
            const message = {
                id: 1,
                method: 'Runtime.evaluate',
                params: {
                    expression: 'document.title',
                    returnByValue: true
                }
            };

            ws.send(JSON.stringify(message));
        });

        ws.on('message', (data) => {
            const msg = JSON.parse(data);
            console.error('收到消息:', JSON.stringify(msg).substring(0, 200));

            if (msg.id === 1 && msg.result) {
                console.log(JSON.stringify({
                    success: true,
                    title: msg.result.result?.value
                }));
                ws.close();
                console.error('完成（标签页保持打开）');
            }
        });

        ws.on('error', (error) => {
            console.error('WebSocket 错误:', error.message);
            process.exit(1);
        });

        // 超时保护
        setTimeout(() => {
            console.error('超时，退出');
            process.exit(1);
        }, 10000);

    } catch (error) {
        console.error('错误:', error.message);
        process.exit(1);
    }
}

testWebSocket();
