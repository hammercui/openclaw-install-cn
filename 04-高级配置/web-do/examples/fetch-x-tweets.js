#!/usr/bin/env node
/**
 * X (Twitter) 首页推文提取
 * 使用CDP连接到浏览器，提取当前可见的推文
 */

const CDP = require('chrome-remote-interface');

async function extractXTweets() {
    try {
        // 1. 获取所有标签页
        const targets = await CDP.List({});

        // 2. 找到 X (Twitter) 的主页或推文页面
        const xTab = targets.find(t =>
            t.type === 'page' &&
            (t.url.includes('x.com') || t.url.includes('twitter.com'))
        );

        if (!xTab) {
            console.error('错误：未找到 X (Twitter) 标签页');
            console.error('请在浏览器中打开：https://x.com');
            process.exit(1);
        }

        console.error(`正在提取：${xTab.title}`);
        console.error(`URL: ${xTab.url}`);

        // 3. 连接到标签页
        const { Runtime, DOM } = await CDP({ target: xTab });

        // 4. 执行 JavaScript 提取推文
        const result = await Runtime.evaluate({
            expression: `
                (function() {
                    const tweets = [];

                    // 查找所有推文
                    const tweetElements = document.querySelectorAll('[data-testid="tweet"]');

                    tweetElements.forEach((tweetEl, index) => {
                        try {
                            // 用户名
                            const userNameEl = tweetEl.querySelector('[data-testid="User-Name"]');
                            const userName = userNameEl ? userNameEl.textContent.trim() : '';

                            // 推文文本
                            const tweetTextEl = tweetEl.querySelector('[data-testid="tweetText"]');
                            const tweetText = tweetTextEl ? tweetTextEl.textContent.trim() : '';

                            // 时间戳
                            const timeEl = tweetEl.querySelector('time');
                            const time = timeEl ? timeEl.getAttribute('datetime') : '';

                            // 链接
                            const linkEl = tweetEl.querySelector('a[href*="/status/"]');
                            const tweetUrl = linkEl ? linkEl.href : '';

                            // 互动数据（回复、转发、点赞）
                            const replyEl = tweetEl.querySelector('[data-testid="reply"]');
                            const retweetEl = tweetEl.querySelector('[data-testid="retweet"]');
                            const likeEl = tweetEl.querySelector('[data-testid="like"]');

                            const replies = replyEl ? parseCount(replyEl.textContent) : '0';
                            const retweets = retweetEl ? parseCount(retweetEl.textContent) : '0';
                            const likes = likeEl ? parseCount(likeEl.textContent) : '0';

                            // 图片数量
                            const imageEls = tweetEl.querySelectorAll('img[src*="pbs.twimg.com"]');
                            const imageCount = imageEls.length;

                            if (userName || tweetText) {
                                tweets.push({
                                    rank: index + 1,
                                    userName,
                                    tweetText: tweetText.substring(0, 500), // 限制长度
                                    time,
                                    url: tweetUrl,
                                    stats: {
                                        replies,
                                        retweets,
                                        likes
                                    },
                                    imageCount
                                });
                            }
                        } catch (e) {
                            // 忽略单个推文的错误
                        }
                    });

                    // 辅助函数：解析数量
                    function parseCount(text) {
                        if (!text) return '0';
                        const match = text.match(/([\\d.]+)([KMB]?)?/);
                        if (!match) return '0';
                        return match[0];
                    }

                    return {
                        total: tweets.length,
                        tweets
                    };
                })();
            `,
            returnByValue: true,
            awaitPromise: true
        });

        // 5. 输出纯 JSON（不输出其他信息）
        const data = result.result.value;
        console.log(JSON.stringify(data, null, 2));

        // 不关闭 CDP 连接，让浏览器标签页保持打开
        // CDP 连接会自动释放

    } catch (error) {
        console.error('错误：', error.message);
        process.exit(1);
    }
}

extractXTweets();
