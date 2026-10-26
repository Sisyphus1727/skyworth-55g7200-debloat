# 预装应用清单与处理分级

> 机型：创维 55G7200 / 8H87 / 酷开 6.2 / Android 5.0
> 包名与路径来自真机 `pm list packages -f` 实测

## 一、已卸载（16 个，可回滚）

全部通过 `pm uninstall -k --user 0` 从用户空间移除，APK 仍保留在系统分区。

| 包名 | 用途 | APK 路径 |
|---|---|---|
| `com.coocaa.ad.webview` | 广告 WebView | `/data/app/com.coocaa.ad.webview-1/base.apk` |
| `com.coocaa.guide` | 开机引导 | `/system/vendor/app/CoocaaGuide/CoocaaGuide.apk` |
| `com.coocaa.messageprovider` | 系统消息/推送 | `/system/vendor/app/MessageBox/MessageBox.apk` |
| `com.tianci.logcatcher` | 日志采集上报 | `/system/vendor/app/SkyDataService/SkyDataService.apk` |
| `com.tianci.push` | 推送服务 | `/system/vendor/app/SkyPushService/SkyPushService.apk` |
| `com.coocaa.x.app.hall` | 应用大厅/商城 | `/system/vendor/app/SkyHall/SkyHall.apk` |
| `com.coocaa.skyoscts` | 工厂自动化测试 | `/system/vendor/app/SkyAutoTest/SkyAutoTest.apk` |
| `com.coocaa.tvpitv` | 电视派（手机推送安装） | `/system/vendor/app/SkyTvPi/SkyTvPi.apk` |
| `com.skyworth.lafite.srtnj.speechserver` | 小维 AI 语音 | `/system/vendor/app/SkyXiaoWei/SkyXiaoWei.apk` |
| `com.skyworth.smarthome_tv` | 小维智联（智能家居） | `/system/vendor/app/SkySmartHome/SkySmartHome.apk` |
| `com.skyworth.voip` | 亲朋圈（视频通话） | `/system/vendor/app/SkyTVQQ/SkyTVQQ.apk` |
| `com.tianci.taskmanager` | 任务管理/电视管家 | `/system/vendor/app/SkyTaskManager/SkyTaskManager.apk` |
| `com.coocaa.remotectrlservice` | 远程协助 | `/system/vendor/app/SkyTVAgent/SkyTVAgent.apk` |
| `com.coocaa.sky.ccapi` | 支付中心 | `/system/vendor/app/SkyPayCenter/SkyPayCenter.apk` |
| `com.tianci.movieplatform` | **酷开桌面**（常驻约 195MB） | `/data/app/com.tianci.movieplatform-1/base.apk` |
| `com.tianci.ad` | **广告服务**（常驻约 49MB） | `/data/app/com.tianci.ad-1/base.apk` |

### 卸载顺序建议

1. 第一批（低风险）：`ad.webview`、`guide`、`messageprovider`、`logcatcher`、`push`
2. 第二批（功能件）：`x.app.hall`、`skyoscts`、`tvpitv`、`speechserver`、`smarthome_tv`
3. 第三批（外围）：`voip`、`taskmanager`、`remotectrlservice`、`sky.ccapi`
4. 第四批（**确认主页已切换成功后再执行**）：`movieplatform`、`ad`

每批后重启一次，确认信号源、设置、本地媒体都正常。

## 二、白名单：不要碰

| 包名 | 作用 | 删/停的后果 |
|---|---|---|
| `com.skyworth.tv` | coocaaTV：电视/HDMI/AV 信号源 | 无法切换信号源，电视功能基本报废 |
| `com.tianci.setting` | 系统设置 | 设置打不开 |
| `com.tianci.system` | 系统服务：遥控器按键、网络时间 | 待机/音量/静音/菜单键失效，时间不同步 |
| `com.tianci.ipc` | 系统通讯框架 | 无法关机/开机 |
| `com.android.packageinstaller` | 软件包安装器 | 装不了 APK |
| `com.android.defcontainer` | 权限帮助程序 | 装 APK 时报错 |
| `com.skyworth.tianciime` | 输入法 | 无法输入文字 |
| `com.android.providers.*` | 媒体/下载/设置 provider | 多媒体、下载异常 |
| `com.skyworth.tv.provider`、`com.android.providers.tv`、`com.skyworthdigital.stb.dataprovider` | 搜台/EPG | 电视搜台异常 |
| `com.skyworth.dtv`、`skyworth.dtvLoader`、`com.skyworth.iSwitchDtvService`、`com.skyworthdigital.idtv` | 数字电视（DTV） | 有线电视不可用 |
| `com.skyworth.factory` | 工厂菜单 | 进不了工厂菜单 |
| `com.tianci.localmedia` | 本地媒体 | U 盘播放不可用 |
| `com.tianci.autoinstaller` | 自动安装器 | 可能影响 U 盘安装流程 |

## 三、灰名单：可按需处理

| 包名 | 用途 | 说明 |
|---|---|---|
| `com.tianci.appstore` | 应用圈 | 卸载后「信号源 → 我的应用」点击无反应 |
| `com.tianci.de` | SkyCast 投屏服务 | 保留（投屏用） |
| `com.tianci.mirror.player` | 投屏播放器 | 保留 |
| `com.skyworth.tv_browser` | 电视浏览器 | 保留（可看网页版视频） |
| `com.tianci.user` | 账号服务 | 保留（部分应用依赖登录态） |
| `com.kuyun.smarttv.coocaatv` | 酷开影视内容 | 保留（自带影视入口） |
| `com.skyworth.bluetoothsoundbarservice` | 蓝牙音响服务 | 保留（外接音响用） |
| `com.coocaa.emergencywarning` | 应急广播 | 政策件，建议保留 |

## 四、恢复命令

```bash
# 单个恢复
adb shell pm install -r --user 0 <上表中的 APK 路径>

# 查找某个包被卸载后的原始路径
adb shell pm list packages -u -f | grep <包名>
```
