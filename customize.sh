#!/system/bin/sh
# 安装入口：兼容 Magisk / KernelSU / APatch 的不同解压约定。
# 前置条件：必须已安装可用的 Google Play Store，否则直接安装失败。
MODPATH=${MODPATH:-/data/adb/modules/coloros_gplaystore_guard}

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }
command -v abort >/dev/null 2>&1 || abort() { echo "$1" >&2; exit 1; }

# ---------- 前置检查：Play Store 必须存在且不是 25KB 系统桩 ----------
P=$(pm path com.android.vending 2>/dev/null | head -1 | sed 's/^package://')
SZ=$(stat -c %s "$P" 2>/dev/null)
V=$(dumpsys package com.android.vending 2>/dev/null | grep -m1 'versionCode=' | sed -n 's/.*versionCode=\([0-9]*\).*/\1/p')
if [ -z "$P" ] || [ ! -f "$P" ] || [ -z "$SZ" ] || [ "$SZ" -le 10000000 ] || [ -z "$V" ]; then
    abort "! 未检测到可用的 Google Play Store（未安装，或当前是 25KB 系统桩）。请先安装/更新 Play Store，再刷入本模块。"
fi

# ---------- 落盘模块文件（三种管理器约定都覆盖） ----------
if [ ! -f "$MODPATH/module.prop" ]; then
    if [ -f "$TMPDIR/module.prop" ]; then
        mkdir -p "$MODPATH"
        cp -af "$TMPDIR"/. "$MODPATH"/ 2>/dev/null
    elif [ -n "$ZIPFILE" ] && [ -f "$ZIPFILE" ]; then
        mkdir -p "$MODPATH"
        unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >/dev/null 2>&1
    fi
fi
[ -f "$MODPATH/module.prop" ] || abort "! 无法写入模块目录: $MODPATH"
rm -rf "$MODPATH/META-INF"
chmod 755 "$MODPATH"/*.sh 2>/dev/null

# ---------- 保存当前 Play Store APK，供系统底包覆盖与兜底重装 ----------
DIR=/data/adb/playstore
mkdir -p "$DIR"
if [ ! -f "$DIR/base.apk" ]; then
    cp -f "$P" "$DIR/base.apk" 2>/dev/null
    chmod 644 "$DIR/base.apk"
    echo "$V" >"$DIR/version.txt"
    ui_print "- 已保存 Play Store APK: versionCode=$V, $SZ bytes"
else
    # 已保存过则保持原样；版本信息以当前安装为准更新
    echo "$V" >"$DIR/version.txt"
    ui_print "- 复用已保存的 Play Store APK（当前 versionCode=$V）"
fi

ui_print "- ColorOS Google Play Store Guard 安装完成"
