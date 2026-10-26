# 创维 55G7200（酷开 6.2）去广告与极简化改造记录

一台 2015 年的创维 55G7200 智能电视，原生酷开桌面广告多、系统卡顿。本仓库记录了**不刷机、可回滚**的改造过程与结果，供同机型（或同代酷开机型）参考。

> 所有操作均在真机验证过，配置有备份、卸载有回滚。但**不同机型/固件差异很大，照做前请先备份、先小批量验证**。

---

## 1. 实测机器信息

| 项 | 值 |
|---|---|
| 型号 / 机芯 | 创维 55G7200 / **8H87** |
| 芯片 | HiSilicon Hi3751V600（arm64-v8a） |
| 系统 | 酷开 6.2，底层 **Android 5.0（API 21）** |
| 内核 | 3.10.61（2018-06 构建） |
| SELinux | Disabled |
| 内存 / 存储 | 2GB / 8GB，4K 面板 |
| 默认主页 | `com.tianci.movieplatform/com.coocaa.homepage.vast.HomePageActivity` |

系统已停止更新（8H87 最后一个大版本为 2018 年的酷开 6.0，6.2 为后续分支），所以不存在"升级后配置被覆盖"的顾虑，但仍建议关闭自动更新。

---

## 2. 改造结果

| 指标 | 改造前 | 改造后 |
|---|---|---|
| 安装包数量 | 63 | **46** |
| 空闲内存 | 846 MB | **1095 MB**（+249MB） |
| 开机广告 | 有 | **无**（配置关闭 + 广告服务卸载） |
| 酷开桌面进程 | 常驻约 195 MB | **已移除** |
| 广告服务进程 | 常驻约 49 MB | **已移除** |
| 主页键行为 | 进酷开广告桌面 | **进第三方桌面（Emotn UI）** |
| 第三方 APK 安装 | 被拦截（提示"请前往应用圈"） | **U 盘/ADB 均可安装** |

开机落点为电视信号源界面（酷开 `NEW_BOOT_FLOW` 的默认行为），按主页键进入第三方桌面。

---

## 3. 原理：三个可改的开关

酷开把绝大部分"系统行为"放在一个 XML 里：

```
/system/pcfg/8H87_G7200/config/general_config.xml
```

其中三个配置项决定了本项目的全部效果：

| 配置项 | 原值 | 改为 | 作用 |
|---|---|---|---|
| `DEFAULT_HOMEPAGE` | `com.tianci.movieplatform/com.coocaa.homepage.vast.HomePageActivity` | 第三方桌面组件名 | 决定主页键归谁 |
| `BOOT_AD` | `true` | `false` | 关闭开机广告 |
| `APP_SELF_INSTALL` | `false` | `true` | 解除"只能从应用圈安装"的限制 |

这个文件是 `root:root 644`、`/system` 只读，**修改它需要一次提权**。本项目使用的是 CVE-2016-5195（Dirty COW）提权：

- **不刷机**：不写 boot、不刷 system 镜像、不改分区表
- **只在内存里打补丁**：重启即复原，失败最多重启一次
- 本项目仅用它改了一个 XML 文件，其余全部用免 root 的 `pm uninstall --user 0` 完成

> 如果你不想提权：只做第 4 节的免 root 部分，也能去掉大部分广告、装上自己的应用，只是主页键仍会回到酷开桌面。

---

## 4. 步骤

### 4.1 开启 ADB

**方式一：工厂菜单**

1. 设置 → 本机信息
2. 遥控器缓慢依次按：**上 上 下 下 左 右 左 右**
3. 工厂菜单 → 通用设置 → **ADB 开关** → 打开
4. **断电重启**（拔插头，不是待机）

**方式二：快速演示模式 + 应用调试**（部分 6.x 版本把 ADB 开关藏了）

1. 设置 → 关于本机 → 本机信息 → 更多信息
2. 白色界面按 **上 上 下 下 左 左 右 右**；灰色界面按 **上 上 下 下 左 右 左 右**
3. 打开「快速演示模式」
4. 回主页 → 我的应用 → 搜索 `YYTS` → 安装「应用调试」
5. 应用调试密码：`69573028`，里面有 ADB 开关和 U 盘安装

电脑端：

```bash
adb connect <电视IP>:5555
adb devices
adb shell getprop ro.build.version.release   # 期望 5.0
adb shell getprop ro.build.version.sdk       # 期望 21
```

> 演示模式会把亮度拉满并循环演示片，用完记得关掉。ADB 5555 是明文端口，改造完成后建议关闭。

### 4.2 备份（必做）

```bash
# 包清单
adb shell pm list packages > packages_before.txt
# 每个包的 APK 路径（卸载后靠它恢复）
adb shell pm list packages -u -f > packages_paths.txt
# 主页配置（world-readable，无需 root）
adb pull /system/pcfg/8H87_G7200/config/general_config.xml .
```

### 4.3 免 root 卸载预装

Android 5.0+ 可用 `pm uninstall -k --user 0`：从用户空间移除，**保留系统里的 APK 文件**，随时可装回。

```bash
adb shell pm uninstall -k --user 0 <包名>
```

本项目实际卸载的 16 个包见 [`docs/packages.md`](docs/packages.md)。

**分批进行**，每批 3–5 个，重启验证一次。绝对不要碰的白名单同样在该文档里。

### 4.4 修改主页与广告开关（需一次提权）

1. 拉取配置，本地改三个值（见第 3 节），推送回 `/data/local/tmp/`
2. 用 CVE-2016-5195（如 [VIKIROOT](https://github.com/hyln9/VIKIROOT)）获取临时 root shell
3. 在 root shell 中执行：

```sh
mount -o remount,rw /system
cp /system/pcfg/8H87_G7200/config/general_config.xml /system/pcfg/8H87_G7200/config/general_config.xml.bak
cp /data/local/tmp/general_config.xml /system/pcfg/8H87_G7200/config/general_config.xml
chmod 644 /system/pcfg/8H87_G7200/config/general_config.xml
chown 0:0 /system/pcfg/8H87_G7200/config/general_config.xml
sync
```

4. 重启，按主页键验证

> 关键顺序：**先确认第三方桌面能正常启动，再卸载 `com.tianci.movieplatform`**。如果主页配置没生效就删原生桌面，会导致主页打不开。

### 4.5 降负载

```bash
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
```

开发者选项里再把「后台进程限制」设为最多 2 个进程（1–2GB 内存的机器收益明显）。

---

## 5. 回滚

```bash
# 恢复单个预装（路径见 docs/packages.md）
adb shell pm install -r --user 0 /system/vendor/app/CoocaaGuide/CoocaaGuide.apk
```

批量恢复脚本：[`scripts/restore.ps1`](scripts/restore.ps1)（配合 `scripts/rollback.sample.json` 使用）。

恢复主页配置（需再次提权）：

```sh
cp /system/pcfg/8H87_G7200/config/general_config.xml.bak \
   /system/pcfg/8H87_G7200/config/general_config.xml
```

系统级兜底：断电 → 按住机身「待机键」不放 → 插电 → 出现齿轮/升级界面后松手 → recovery 恢复出厂。

---

## 6. 改造中发现的三个坑

### 6.1 STR 待机导致"遥控器叫不醒"

**症状**：待机后红灯常亮，遥控器和机身按键都没反应，必须拔插头才能开。

**原因**：`getprop coocaa.sys.suspend` 为 `1`，即启用了 STR（挂起内存）待机。这台机型的 STR 恢复不可靠，挂起后 SoC 不响应唤醒信号。

**临时解决**（重启失效，属性不带 `persist.` 前缀）：

```bash
adb shell setprop coocaa.sys.suspend 0
adb shell setprop third.get.quickplay 0
```

设置后关机 → 10 秒内可再次开机，实测连续三次正常。

**注意**：工厂菜单里的「快速开机」开关**不一定**写这个属性，实测改了之后 `coocaa.sys.suspend` 仍为 1。要永久生效需要在开机脚本（如 `/system/bin/install-recovery.sh`）里置 0，需要 root。

### 6.2 大 APK 安装会让 adbd 掉线

安装 8–13MB 的 APK 时，adb 经常在安装阶段变成 `offline`（端口还开着但握手失败），需要断电重启恢复。

**规避**：改用 U 盘安装（`APP_SELF_INSTALL=true` 后可正常安装），或先 `adb push` 到 `/data/local/tmp/` 再在设备上 `pm install`。

### 6.3 `pm hide` 与 `pm uninstall --user 0` 的区别

- `pm uninstall --user 0`：应用从桌面消失、进程不再启动，**APK 保留**，可 `pm install` 恢复
- `pm hide`：隐藏但保留数据，恢复用 `pm unhide`

本机 `pm hide` 未被使用；`pm uninstall -k --user 0` 实测可靠，且恢复路径明确。

---

## 7. 参考

- [同机型 Root 与精简实录（55G7200 / 8H87）](https://www.xfy9326.top/posts/g7200_8h87_root/) — 本项目 `DEFAULT_HOMEPAGE` 方案的依据
- [ZNDS：串口大法就是好-酷开电视没得跑（三）系统分析](https://www.znds.com/tv-1253996-1-1.html) — 酷开 `/system/pcfg` 配置机制与包作用分析
- [ZNDS：创维电视的广告如何删除](https://www.znds.com/tv-1250483-1-1.html) — 预装包清单
- [ZNDS：创维/酷开电视如何用 U 盘安装第三方软件](https://www.znds.com/tv-1251940-1-1.html) — 快速演示模式 + 应用调试流程
- [VIKIROOT（CVE-2016-5195 临时提权）](https://github.com/hyln9/VIKIROOT)
- 广告域名清单见 [`docs/ad-domains.md`](docs/ad-domains.md)

---

## 8. 免责声明

本项目仅为个人设备改造记录，不保证适用于其他机型或固件版本。修改系统文件、卸载系统应用、使用提权工具均存在风险，操作前请自行备份并确认可恢复方式。因照做导致的设备故障、数据丢失等问题由操作者自行承担。

## License

[MIT](LICENSE)
