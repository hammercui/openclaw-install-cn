#!/usr/bin/env node
/**
 * X (Twitter) 首页时间线提取
 * 专门针对 https://x.com/home 页面
 */

const CDP = require('chrome-remote-interface');

async function extractXHomeTimeline() {
    try {
        // 1. 获取所有标签页
        const targets = await CDP.List({});

        // 2. 找到 X 首页
        const homeTab = targets.find(t =>
            t.type === 'page' &&
            t.url.includes('x.com/home')
        );

        if (!homeTab) {
            console.error('错误：未找到 X 首页 (https://x.com/home)');
            console.error('请在浏览器中打开：https://x.com/home');
            process.exit(1);
        }

        console.error(`正在提取：X 首页时间线`);
        console.error(`URL: ${homeTab.url}`);

        // 3. 连接到标签页
        const { Runtime } = await CDP({ target: homeTab });

        // 4. 等待页面加载
        await new Promise(resolve => setTimeout(resolve, 2000));

        // 5. 执行 JavaScript 提取时间线
        const result = await Runtime.evaluate({
            expression: `
                (function() {
                    const tweets = [];

                    // 查找所有推文（主页时间线）
                    const tweetElements = document.querySelectorAll('[data-testid="tweet"]');

                    console.log('找到推文数量:', tweetElements.length);

                    tweetElements.forEach((tweetEl, index) => {
                        try {
                            // 用户名和handle
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

                            // 推文文本
                            const tweetTextEl = tweetEl.querySelector('[data-testid="tweetText"]');
                            const tweetText = tweetTextEl ? tweetTextEl.textContent.trim() : '';

                            // 媒体内容（图片/视频）
                            const mediaEls = tweetEl.querySelectorAll('img[src*="pbs.twimg.com"], video');
                            const mediaCount = mediaEls.length;

                            // 时间戳
                            const timeEl = tweetEl.querySelector('time');
                            const time = timeEl ? timeEl.getAttribute('datetime') : '';

                            // 链接
                            const linkEl = tweetEl.querySelector('a[href*="/status/"]');
                            const tweetUrl = linkEl ? 'https://x.com' + linkEl.getAttribute('href') : '';

                            // 互动数据
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

                            // 是否是转推
                            const retweetIndicator = tweetEl.querySelector('[data-testid="socialContext"]');
                            const isRetweet = retweetIndicator ? retweetIndicator.textContent.trim() : '';

                            // 广告标识
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
                                    stats: {
                                        replies,
                                        retweets,
                                        likes
                                    },
                                    mediaCount,
                                    isRetweet,
                                    isAd
                                });
                            }
                        } catch (e) {
                            // 忽略单个推文的错误
                        }
                    });

                    // 统计信息
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
        });

        // 6. 输出纯 JSON
        const data = result.result.value;
        console.log(JSON.stringify(data, null, 2));

        // 不关闭 CDP 连接，让浏览器标签页保持打开
        // CDP 连接会自动释放

    } catch (error) {
        console.error('错误：', error.message);
        process.exit(1);
    }
}

extractXHomeTimeline();
