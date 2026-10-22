> **本仓库完全由 AI 生成与测试。**

# ColorOS Google Play Store Guard

- **作者**：BHLuotianyi
- **版本**：1.0.0
- **测试于**：一加 13 / ColorOS 17.0.0.103(CN01)
- **适用**：存在 `boot_monitor_service` 与 `persist.sys.boot_monitor.mode` 的国行 ColorOS / OPPO / OnePlus
- **Root**：KernelSU / KernelSU-Next / Magisk / APatch

## 下载

- [dist/ColorOS-Google-Play-Store-Guard-v1.0.0.zip](dist/ColorOS-Google-Play-Store-Guard-v1.0.0.zip)

## 问题

ColorOS 在判定「启动异常」（常见于软重启 / framework 重启）后，`boot_monitor_service` 会写入：

```
persist.sys.boot_monitor.mode = pms_restore
```

PackageManagerService 读到该值后进入 **special safe mode**，把 `com.android.vending` 从 /data 的更新版本回滚到：

```
/product/priv-app/GooglePlayServicesUpdater/GooglePlayServicesUpdater.apk   （约 25 KB 的系统桩）
```

结果：桌面 Google Play 图标消失，依赖 Google Play 环境的银行/钱包类应用会报「缺少 Google Play 环境」。

## 拦截的是什么信号

**只拦截 `persist.sys.boot_monitor.mode=pms_restore` 这一个信号。**

- `boot_monitor_service` **不停用、不禁用**；
- 它的其它救援阶梯（SS / SystemUI / Launcher loop、opex、recovery 等）不受影响；
- 常驻 watcher 每 0.1 秒检查一次该属性，发现 `pms_restore` 立即清空，使 PMS 不会进入 safe mode。

## 它做什么

1. **信号拦截（主逻辑）**
   见上。软重启后 PMS 读到的 mode 为空，不再回滚系统应用。

2. **系统底包兜底（可选）**
   安装时抓取当前可用的 Play Store APK（必须 >10MB，自动跳过 25KB 系统桩），之后把它 bind-mount 到系统桩路径，并遮蔽给旧桩编译的 `oat` 目录。
   即使某次拦截失败、PMS 进入 safe mode，回滚目标也是同一个可用版本的 Play Store。
   源文件放在 `/data/local/tmp`：KSU 会把 `/data/adb` 来源的挂载从 app namespace 隐藏，直接用 `/data/adb` 做源会导致 app 端仍看到 25KB 桩。

3. **兜底重装**
   守护进程每 10 秒检查 `versionCode`；低于已保存版本或包被移除时，用保存的 APK `pm install -r`（保留数据）。

## 安装前置条件（重要）

**必须已经安装可用的 Google Play Store（不是 25KB 系统桩）。**

安装脚本会检查：

```
pm path com.android.vending      → 必须存在
APK 大小                         → 必须 > 10 MB
versionCode                      → 必须可读
```

任一条件不满足，**安装直接失败**，并提示：

```
! 未检测到可用的 Google Play Store（未安装，或当前是 25KB 系统桩）。
  请先安装/更新 Play Store，再刷入本模块。
```

也就是说：如果设备上的 Play Store 已经消失或只剩系统桩，请先手动安装/更新 Play Store，再刷本模块。

## 安装

1. 确认 Play Store 可正常打开。
2. 在 KernelSU / Magisk / APatch 管理器中刷入本模块 ZIP。
3. 安装器会保存当前 Play Store APK 到 `/data/adb/playstore/base.apk`。
4. 无需重启即可生效；重启后由 `post-fs-data.sh` / `service.sh` 自动恢复。

## 日常使用

- **软重启**（framework / zygote 重启）：watcher 与守护进程继续运行，Play Store 不会被回滚。
- **真重启 + 重新越狱**（LKM 等 root 不在启动阶段生效的场景）：
  重新拿到 root 后执行一次：
  ```sh
  su -c sh /data/adb/modules/coloros_gplaystore_guard/apply_fix.sh
  ```
  如果你的越狱流程会执行 `ksud late-load`，模块的 `late-load.sh` 会自动补跑。
- **查看状态**：模块页的「动作」按钮会打印：
  `boot_monitor_service` 状态、当前 `pms_restore` 值、Play Store 版本/路径、watcher/daemon 是否运行、系统底包大小、最近一次拦截/重装记录。

## 卸载

在管理器中卸载模块即可。卸载脚本会停止本模块的 watcher/daemon 并删除 `/data/adb/playstore`。
系统底包的 bind mount 会在重启后自动消失；若不重启，建议手动重启一次。

## 注意

- 本模块只处理 `pms_restore` 这一个信号，不隐藏 root、不改 Play Integrity、不影响其它应用的安全策略。
- 若 ROM 没有 `boot_monitor_service` / `persist.sys.boot_monitor.mode`，模块会静默待命，无副作用。
- 保存的 Play Store APK 仅用于本机重装，模块 ZIP 不包含 Google 的 APK。
- Play Store 更新后，如需刷新系统底包与兜底版本，重跑一次 `apply_fix.sh`。

## 构建

```sh
sh build.sh
```

输出：`dist/ColorOS-Google-Play-Store-Guard-v<version>.zip`

## License

MIT
