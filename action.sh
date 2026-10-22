#!/system/bin/sh
# 模块动作按钮：显示运行状态。
DIR=/data/adb/playstore
TGT=/product/priv-app/GooglePlayServicesUpdater/GooglePlayServicesUpdater.apk

echo "boot_monitor_service : $(getprop init.svc.boot_monitor_service)"
echo "boot_monitor.mode    : [$(getprop persist.sys.boot_monitor.mode)]"
echo "Play Store           : $(dumpsys package com.android.vending 2>/dev/null | grep -m1 versionCode= | sed 's/^ *//')"
echo "  codePath           : $(dumpsys package com.android.vending 2>/dev/null | grep -m1 codePath= | sed 's/^ *codePath=//')"
echo "watcher              : $([ -d "$DIR/watcher.lock" ] && echo running || echo stopped)"
echo "guard daemon         : $([ -d "$DIR/daemon.lock" ] && echo running || echo stopped)"
echo "saved APK            : $(stat -c %s "$DIR/base.apk" 2>/dev/null) bytes, version=$(cat "$DIR/version.txt" 2>/dev/null)"
echo "system base APK      : $(stat -c %s "$TGT" 2>/dev/null) bytes"
echo "system base oat      : $([ -n "$(ls -A /product/priv-app/GooglePlayServicesUpdater/oat 2>/dev/null)" ] && echo visible || echo masked)"
echo
echo "last intercept       : $(tail -1 "$DIR/intercept.log" 2>/dev/null)"
echo "last restore         : $(tail -1 "$DIR/restore.log" 2>/dev/null)"
