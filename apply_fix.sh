#!/system/bin/sh
# 主逻辑：可重复执行。
# 1) 若已保存 Play Store APK：把系统桩替换成可用的同版本 APK（ColorOS 专有路径，不存在则跳过）。
# 2) 启动 watcher：只清掉 persist.sys.boot_monitor.mode=pms_restore，boot_monitor_service 继续运行。
# 3) 启动兜底守护：Play Store 被移除或版本低于已保存版本时自动重装。

MODDIR=${MODDIR:-${0%/*}}
DIR=/data/adb/playstore
APK=$DIR/base.apk
STAGE=/data/local/tmp/.ps_base.apk
TGT=/product/priv-app/GooglePlayServicesUpdater/GooglePlayServicesUpdater.apk
STUBDIR=/product/priv-app/GooglePlayServicesUpdater

mkdir -p "$DIR"

start_bg() {
    if [ -x /data/adb/ksu/bin/busybox ]; then
        /data/adb/ksu/bin/busybox setsid "$@" >/dev/null 2>&1 </dev/null &
    elif [ -x /data/adb/magisk/busybox ]; then
        /data/adb/magisk/busybox setsid "$@" >/dev/null 2>&1 </dev/null &
    elif command -v setsid >/dev/null 2>&1; then
        setsid "$@" >/dev/null 2>&1 </dev/null &
    else
        "$@" >/dev/null 2>&1 </dev/null &
    fi
}

# 1) 系统底包：必须是 /data/local/tmp 下的源文件，KSU 会把 /data/adb 来源的挂载
#    从 app namespace 里隐藏。
if [ -f "$APK" ] && [ -f "$TGT" ]; then
    want=$(stat -c %s "$APK" 2>/dev/null)
    have=$(stat -c %s "$TGT" 2>/dev/null)
    if [ "$want" != "$have" ]; then
        cp -f "$APK" "$STAGE" 2>/dev/null
        chmod 644 "$STAGE" 2>/dev/null
        chcon u:object_r:system_file:s0 "$STAGE" 2>/dev/null
        mount --bind "$STAGE" "$TGT" 2>/dev/null
    fi
    # 遮蔽给 25KB 桩编译的旧 odex/vdex
    mkdir -p /data/local/tmp/ps-empty
    if [ -n "$(ls -A "$STUBDIR/oat" 2>/dev/null)" ]; then
        mount --bind /data/local/tmp/ps-empty "$STUBDIR/oat" 2>/dev/null
    fi
fi

# 2) 信号拦截
[ -d "$DIR/watcher.lock" ] || start_bg /system/bin/sh "$MODDIR/watcher.sh"

# 3) 兜底重装
if [ -f "$APK" ]; then
    [ -d "$DIR/daemon.lock" ] || start_bg /system/bin/sh "$MODDIR/daemon.sh"
fi
