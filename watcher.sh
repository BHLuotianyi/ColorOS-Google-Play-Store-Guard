#!/system/bin/sh
# 只拦截 pms_restore 这一个信号；boot_monitor_service 不停、不改。
DIR=/data/adb/playstore
LOCK=$DIR/watcher.lock
LOG=$DIR/intercept.log

mkdir "$LOCK" 2>/dev/null || exit 0
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM HUP

while :; do
    if [ "$(getprop persist.sys.boot_monitor.mode)" = "pms_restore" ]; then
        setprop persist.sys.boot_monitor.mode ""
        echo "$(date '+%F %T') intercepted pms_restore" >>"$LOG"
    fi
    sleep 0.1
done
