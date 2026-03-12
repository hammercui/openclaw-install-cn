#!/usr/bin/env node
/**
 * X (Twitter) 首页时间线提取 - 不使用chrome-remote-interface库
 * 直接通过WebSocket连接CDP
 */

const WebSocket = require('ws');

async function extractXHomeTimeline() {
    let ws = null;

    try {
        console.error(`正在提取：X 首页时间线`);

        // 1. 获取所有标签页
        const response = await fetch('http://localhost:9222/json');
        const tabs = await response.json();

        // 2. 找到 X 首页
        const homeTab = tabs.find(t =>
            t.type === 'page' &&
            t.url.includes('x.com/home')
        );

        if (!homeTab) {
            console.error('错误：未找到 X 首页 (https://x.com/home)');
            console.error('请在浏览器中打开：https://x.com/home');
            process.exit(1);
        }

        console.error(`URL: ${homeTab.url}`);

        // 3. 连接到 CDP WebSocket
        const wsUrl = homeTab.webSocketDebuggerUrl;
        ws = new WebSocket(wsUrl);

        // 4. 等待连接打开
        await new Promise((resolve, reject) => {
            ws.on('open', resolve);
            ws.on('error', reject);
        });

        console.error('CDP 连接成功');

        // 5. 启用 Runtime
        await new Promise((resolve, reject) => {
            const msg = { id: 1, method: 'Runtime.enable', params: {} };
            ws.send(JSON.stringify(msg));

            const handler = (data) => {
                const response = JSON.parse(data);
                if (response.id === 1) {
                    ws.removeListener('message', handler);
                    if (response.error) {
                        reject(new Error(response.error.message));
                    } else {
                        resolve();
                    }
                }
            };
            ws.on('message', handler);
        });

        // 6. 执行 JavaScript 提取时间线
        const data = await new Promise((resolve, reject) => {
            const msg = {
                id: 2,
                method: 'Runtime.evaluate',
                params: {
                    expression: `
                        (function() {
                            const tweets = [];
                            const tweetElements = document.querySelectorAll('[data-testid="tweet"]');

                            tweetElements.forEach((tweetEl, index) => {
                                try {
                                    const userNameEl = tweetEl.querySelector('[data-testid="User-Name"]');
                                    let userName = '';
                                    let userHandle = '';

                                    if (userNameEl) {
                                        const spans = userNameEl.querySelectorAll('span');
                                        const texts = Array.from(spans).map(s => s.textContent.trim()).filter(t => t);
                                        if (texts.length >= 2) {
                                            userName = texts[0];
                                            userHandle = texts[1];
                                        }
                                    }

                                    const tweetTextEl = tweetEl.querySelector('[data-testid="tweetText"]');
                                    const tweetText = tweetTextEl ? tweetTextEl.textContent.trim() : '';

                                    const mediaEls = tweetEl.querySelectorAll('img[src*="pbs.twimg.com"], video');
                                    const mediaCount = mediaEls.length;

                                    const timeEl = tweetEl.querySelector('time');
                                    const time = timeEl ? timeEl.getAttribute('datetime') : '';

                                    const linkEl = tweetEl.querySelector('a[href*="/status/"]');
                                    const tweetUrl = linkEl ? 'https://x.com' + linkEl.getAttribute('href') : '';

                                    const replyEl = tweetEl.querySelector('[data-testid="reply"]');
                                    const retweetEl = tweetEl.querySelector('[data-testid="retweet"]');
                                    const likeEl = tweetEl.querySelector('[data-testid="like"]');

                                    const getStatCount = (el) => {
                                        if (!el) return '0';
                                        const text = el.textContent.trim();
                                        if (!text || text === '回复' || text === '转发' || text === '喜欢') return '0';
                                        return text;
                                    };

                                    const replies = getStatCount(replyEl);
                                    const retweets = getStatCount(retweetEl);
                                    const likes = getStatCount(likeEl);

                                    const retweetIndicator = tweetEl.querySelector('[data-testid="socialContext"]');
                                    const isRetweet = retweetIndicator ? retweetIndicator.textContent.trim() : '';

                                    const adIndicator = tweetEl.querySelector('[data-testid="promotedIndicator"]');
                                    const isAd = !!adIndicator;

                                    if (userName || tweetText) {
                                        tweets.push({
                                            rank: index + 1,
                                            userName,
                                            userHandle,
                                            tweetText: tweetText.substring(0, 500),
                                            time,
                                            url: tweetUrl,
                                            stats: { replies, retweets, likes },
                                            mediaCount,
                                            isRetweet,
                                            isAd
                                        });
                                    }
                                } catch (e) {
                                    // 忽略错误
                                }
                            });

                            const adsCount = tweets.filter(t => t.isAd).length;
                            const retweetsCount = tweets.filter(t => t.isRetweet).length;

                            return {
                                summary: {
                                    total: tweets.length,
                                    organic: tweets.length - adsCount,
                                    ads: adsCount,
                                    retweets: retweetsCount
                                },
                                tweets
                            };
                        })();
                    `,
                    returnByValue: true,
                    awaitPromise: true
                }
            };

            ws.send(JSON.stringify(msg));

            const handler = (data) => {
                const response = JSON.parse(data);
                if (response.id === 2) {
                    ws.removeListener('message', handler);
                    if (response.error) {
                        reject(new Error(response.error.message));
                    } else {
                        resolve(response.result.result.value);
                    }
                }
            };
            ws.on('message', handler);
        });

        // 7. 输出纯 JSON
        console.log(JSON.stringify(data, null, 2));

        // 8. 关闭 WebSocket 连接（但不关闭浏览器标签页）
        ws.close();

        console.error('\n✅ 提取完成（浏览器标签页保持打开）');

    } catch (error) {
        console.error('错误：', error.message);
        if (ws) ws.close();
        process.exit(1);
    }
}

extractXHomeTimeline();
