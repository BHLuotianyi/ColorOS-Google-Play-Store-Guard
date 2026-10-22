<p align="center"><strong>English</strong> | <a href="README.md">简体中文</a></p>

> **This repository is fully generated and tested by AI.**

# ColorOS Google Play Store Guard

<p align="center">
  <a href="https://github.com/BHLuotianyi/ColorOS-Google-Play-Store-Guard/releases/latest"><img alt="release" src="https://img.shields.io/github/v/release/BHLuotianyi/ColorOS-Google-Play-Store-Guard?label=release&style=flat-square"></a>
  <img alt="last commit" src="https://img.shields.io/github/last-commit/BHLuotianyi/ColorOS-Google-Play-Store-Guard?style=flat-square">
  <a href="LICENSE"><img alt="license" src="https://img.shields.io/github/license/BHLuotianyi/ColorOS-Google-Play-Store-Guard?style=flat-square"></a>
  <img alt="root" src="https://img.shields.io/badge/root-KernelSU%20%7C%20KernelSU--Next%20%7C%20Magisk%20%7C%20APatch-blue?style=flat-square">
</p>

- **Author**: BHLuotianyi
- **Tested on**: OnePlus 13 / ColorOS 17.0.0.103(CN01)
- **Applies to**: China-region ColorOS builds with `boot_monitor_service` and `persist.sys.boot_monitor.mode`

## Download

[![Downloads](https://img.shields.io/github/downloads/BHLuotianyi/ColorOS-Google-Play-Store-Guard/total?style=flat-square)](https://github.com/BHLuotianyi/ColorOS-Google-Play-Store-Guard/releases)

Download the latest `ColorOS-Google-Play-Store-Guard-v*.zip` from [Releases](https://github.com/BHLuotianyi/ColorOS-Google-Play-Store-Guard/releases/latest).

## Installation prerequisites (important)

**A working Google Play Store must already be installed (not the 25 KB system stub).**

The installer checks:

```
pm path com.android.vending      → must exist
APK size                         → must be > 10 MB
versionCode                      → must be readable
```

If any check fails, **installation fails immediately** with:

```
! No usable Google Play Store detected (not installed, or currently the 25 KB system stub).
  Install/update Play Store first, then flash this module.
```

In other words: if Play Store is gone or only the stub remains, install/update Play Store manually before flashing this module.

## Installation

1. Make sure Play Store opens normally.
2. Flash this module ZIP in KernelSU / Magisk / APatch.
3. The installer saves the current Play Store APK to `/data/adb/playstore/base.apk`.
4. It takes effect without a reboot; after a reboot, `post-fs-data.sh` / `service.sh` restore it automatically.

## Problem

After ColorOS decides a boot was "abnormal" (typically after a soft reboot / framework restart), `boot_monitor_service` writes:

```
persist.sys.boot_monitor.mode = pms_restore
```

When PackageManagerService reads this value, it enters **special safe mode** and rolls `com.android.vending` back from the updated version in /data to:

```
/product/priv-app/GooglePlayServicesUpdater/GooglePlayServicesUpdater.apk   (~25 KB system stub)
```

Result: the Google Play icon disappears from the launcher, and some apps that rely on Google Play report a missing Google Play environment.

## What signal is intercepted

**Only the `persist.sys.boot_monitor.mode=pms_restore` signal is intercepted.**

- `boot_monitor_service` is **not stopped or disabled**;
- Its other recovery ladders (SS / SystemUI / Launcher loop, opex, recovery, etc.) are unaffected;
- A resident watcher checks the property every 0.1 s; on seeing `pms_restore` it clears it immediately, so PMS never enters safe mode.

## What it does

1. **Signal interception (main logic)**
   See above. After a soft reboot PMS reads an empty mode and no longer rolls back system apps.

2. **System base package fallback (optional)**
   During installation it captures the currently usable Play Store APK (must be >10 MB; the 25 KB system stub is skipped automatically), then bind-mounts it over the system stub path and masks the `oat` directory compiled for the old stub.
   Even if interception fails once and PMS enters safe mode, the rollback target is the same usable Play Store version.
   The source file lives in `/data/local/tmp`: KSU hides mounts originating from `/data/adb` from the app namespace, so using `/data/adb` as the source would still show apps the 25 KB stub.

3. **Fallback reinstall**
   The daemon checks `versionCode` every 10 s; if it is lower than the saved version or the package is missing, it runs `pm install -r` with the saved APK (keeping data).

## Daily use

- **Soft reboot** (framework / zygote restart): the watcher and daemon keep running; Play Store is not rolled back.
- **Full reboot + re-root** (LKM and other setups where root is not active at boot):
  After regaining root, run once:
  ```sh
  su -c sh /data/adb/modules/coloros_gplaystore_guard/apply_fix.sh
  ```
  If your rooting flow runs `ksud late-load`, the module's `late-load.sh` re-applies it automatically.
- **Check status**: the module's Action button prints:
  `boot_monitor_service` state, current `pms_restore` value, Play Store version/path, whether watcher/daemon are running, system base package size, and the last interception/reinstall record.

## Uninstall

Uninstall the module in your manager. The uninstall script stops this module's watcher/daemon and removes `/data/adb/playstore`.
The system base package bind mount disappears after a reboot; if you don't reboot, a manual reboot is recommended.

## Notes

- This module only handles the `pms_restore` signal. It does not hide root, change Play Integrity, or affect other apps' security policies.
- If the ROM lacks `boot_monitor_service` / `persist.sys.boot_monitor.mode`, the module stays idle silently with no side effects.
- The saved Play Store APK is only used for local reinstalls; the module ZIP does not contain Google's APK.
- After Play Store updates, re-run `apply_fix.sh` if you want to refresh the system base package and fallback version.

## Build

```sh
sh build.sh
```

Output: `dist/ColorOS-Google-Play-Store-Guard-v<version>.zip`

## License

MIT
