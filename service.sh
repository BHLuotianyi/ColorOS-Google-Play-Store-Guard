#!/system/bin/sh
MODDIR=${0%/*}
[ -x "$MODDIR/apply_fix.sh" ] && sh "$MODDIR/apply_fix.sh"
