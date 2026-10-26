# 创维 / 酷开广告与推送域名清单

在路由器上把这些域名指向 `127.0.0.1`（或直接加入 AdGuard Home 的拦截规则），可以拦掉系统层之外的广告请求、推送与升级检测。

> 系统级广告（开机广告、桌面推荐位）已通过 `BOOT_AD=false` + 卸载 `com.tianci.ad` 解决；这份清单是**兜底层**，用于拦截酷开 App 内部的广告 SDK。

## 清单

```text
# 创维 / 酷开 广告与推送
api.app.skysrt.com
api.upgrade.skysrt.com
update01.skyworth-cloud.com
update01.skyworth-cloud.com.wswebpic.com
hoisin.coocaatv.com
res.hoisin.coocaatv.com
log.skysrt.com
apk.sky.fs.skysrt.com
api.device.skysrt.com
push.skysrt.com

# 通用广告 / 统计 SDK
umengacs.m.taobao.com
amdcopen.m.taobao.com
alog.umeng.com
uop.umeng.com
s.jpush.cn
stats.jpush.cn
sis.jpush.io
p.tencentmind.com
tracker.appadhoc.com
admaster.com.cn
vqq.admaster.com.cn
taps.net
miaozhen.com
ad.3.cn
irs01.com
```

## 副作用（实测与社区反馈）

- 「影视」入口进资源时会在进度条停留约 30 秒
- 系统检测不到更新（预期行为）
- 若某个应用无法联网，先怀疑是误伤，逐条移除对应域名验证

## 生效方式

1. 路由器自定义 hosts（小米 / 华为 / OpenWrt / AdGuard Home 均支持），域名指向 `127.0.0.1`
2. 电视端：电视管家 → 空间清理 → 清空「应用缓存 / 应用数据」
3. 重启电视

## 来源

- [ZNDS：2019 最新创维去广告教程](https://www.znds.com/tv-1134133-1-1.html)
- [ZNDS：创维酷开电视屏蔽广告教程（小米路由器 hosts）](https://www.znds.com/tv-1249128-1-1.html)
