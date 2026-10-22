#!/system/bin/sh
# KernelSU late-load 钩子：冷启动后 root 迟到时补跑一次。
MODDIR=${0%/*}
[ -x "$MODDIR/apply_fix.sh" ] && sh "$MODDIR/apply_fix.sh"
