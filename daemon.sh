#!/system/bin/sh
# 兜底守护：Play Store 被移除，或版本低于已保存版本时，自动重装保存的 APK。
DIR=/data/adb/playstore
APK=$DIR/base.apk
LOG=$DIR/restore.log
LOCK=$DIR/daemon.lock
WANT=$(cat "$DIR/version.txt" 2>/dev/null)

[ -f "$APK" ] || exit 0
[ "$(stat -c %s "$APK" 2>/dev/null)" -gt 10000000 ] || exit 0
[ -n "$WANT" ] || exit 0

mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM HUP

version() {
    dumpsys package com.android.vending 2>/dev/null | grep -m1 "versionCode=" | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p'
}

# 版本读不到时，先判断 package 服务是否可用：
# framework 重启期间 cmd/pm/dumpsys 都会暂时失败，此时视为“未知”，不做重装。
healthy() {
    v=$(version)
    if [ -n "$v" ]; then
        [ "$v" -ge "$WANT" ]
        return
    fi
    cmd package list packages com.android.vending >/dev/null 2>&1 || return 0
    return 1
}

restore() {
    TMP=/data/local/tmp/.playstore_restore.apk
    echo "$(date '+%F %T') restore start: ver=$(version) mode=$(getprop persist.sys.boot_monitor.mode)" >>"$LOG"
    if cp -f "$APK" "$TMP" && chmod 644 "$TMP"; then
        pm install -r --user 0 "$TMP" >>"$LOG" 2>&1
    else
        echo "$(date '+%F %T') staging failed" >>"$LOG"
    fi
    echo "$(date '+%F %T') restore done: ver=$(version)" >>"$LOG"
}

i=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    i=$((i + 1))
    [ "$i" -gt 300 ] && break
    sleep 2
done
sleep 5

fail=0
while :; do
    sleep 10
    [ "$(getprop sys.boot_completed)" = "1" ] || { fail=0; continue; }
    if healthy; then
        fail=0
        continue
    fi
    fail=$((fail + 1))
    if [ "$fail" -ge 2 ]; then
        restore
        fail=0
    fi
done
