# 启动失败FAQ

## 1.从老版本到2026.3.13启动失败

根据输出信息，主要有两个问题：  

1. 服务配置过期（根本原因）  

Service config issue: Gateway service embeds OPENCLAW_GATEWAY_TOKEN and should be reinstalled.  

旧版服务文件 gateway.cmd 中内嵌了 token，与当前配置不一致，导致 gateway 启动后无法正常工作。  

2. RPC 探测失败（表现症状）  

gateway closed (1006 abnormal closure (no close frame))  

WebSocket 连接异常关闭，说明 gateway 进程虽然启动了但立即崩溃或拒绝连接。  

解决方案  

按照它的建议，重新安装 gateway 服务：  

openclaw gateway install --force  
openclaw gateway start  

然后再检查状态：  

openclaw gateway status  

如果仍有问题，运行诊断：  

openclaw doctor --repair  

也可以查看日志文件 \tmp\openclaw\openclaw-2026-03-20.log 确认具体错误。

## 2.
