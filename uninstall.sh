#!/system/bin/sh
# 卸载：停掉本模块的 watcher/daemon，清理运行时目录。
# 系统底包/oat 的 bind mount 会在重启后消失；如不重启，可手动 umount。
MODDIR=${0%/*}
for p in /proc/[0-9]*; do
    c=$(tr '\0' ' ' <"$p/cmdline" 2>/dev/null)
    case "$c" in
        *"/coloros_gplaystore_guard/watcher.sh "*) kill -9 "${p#/proc/}" ;;
        *"/coloros_gplaystore_guard/daemon.sh "*) kill -9 "${p#/proc/}" ;;
    esac
done
rm -rf /data/adb/playstore
