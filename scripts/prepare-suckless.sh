#!/usr/bin/env bash

# 任意命令失败时立即停止。
set -e

# 本仓库目录。
DESKTOP_DIR="$HOME/workspace/personal/debian-desktop"

# suckless 源码统一存放位置。
SUCKLESS_DIR="$DESKTOP_DIR/suckless"

echo "==> 更新 Debian 软件包索引"
sudo apt-get update

echo "==> 安装最小依赖"

sudo apt-get install --no-install-recommends -y \
    build-essential \
    git \
    pkg-config \
    xserver-xorg-core \
    xserver-xorg-input-libinput \
    xinit \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    libfontconfig1-dev \
    libfreetype-dev \
    fonts-jetbrains-mono \
    fonts-noto-cjk

# 上面每个软件包的用途：
#
# build-essential
#   提供 gcc、make 等工具，用于编译 dwm、st、dmenu。
#
# git
#   用于从 suckless 官方仓库下载源码。
#
# pkg-config
#   编译 st 时用于查找 fontconfig 和 freetype。
#
# xserver-xorg-core
#   X11 显示服务器核心。dwm 运行在它上面。
#   它不是图形登录界面，也不是完整桌面环境。
#
# xserver-xorg-input-libinput
#   让 X11 支持键盘、鼠标和触控板。
#
# xinit
#   提供 startx，用于从命令行启动 X11 和 dwm。
#
# libx11-dev
#   X11 基础开发接口，三个 suckless 程序都需要。
#
# libxft-dev
#   X11 字体渲染接口，负责绘制抗锯齿字体。
#
# libxinerama-dev
#   dwm 的多显示器支持。
#
# libfontconfig1-dev
#   编译 st 时用于查找和匹配系统字体。
#
# libfreetype-dev
#   编译 st 时使用的字体渲染开发库。
#
# fonts-jetbrains-mono
#   JetBrains Mono 字体，供 dwm、st 和 dmenu 使用。
#
# fonts-noto-cjk
#   提供简体中文、繁体中文、日文和韩文字形。
#   当 JetBrains Mono 不包含中文字符时，由它负责字体回退，
#   避免终端、浏览器和 IDE 中的中文显示为方框。

mkdir -p "$SUCKLESS_DIR"

download_source() {
    name="$1"
    url="$2"
    target="$SUCKLESS_DIR/$name"

    if [ -d "$target" ]; then
        echo "==> $name 已存在，跳过下载"
        return
    fi

    echo "==> 下载 $name 官方源码"
    git clone --depth 1 "$url" "$target"

    # 删除源码内部的 Git 信息。
    # 这样源码可以直接提交到外层 debian-desktop 仓库，
    # 不会形成 Git 嵌套仓库。
    rm -rf "$target/.git"
}

# dwm：动态窗口管理器，负责窗口布局、快捷键和状态栏。
download_source "dwm" "https://git.suckless.org/dwm"

# st：极简终端模拟器，dwm 默认快捷键会启动它。
download_source "st" "https://git.suckless.org/st"

# dmenu：极简程序启动器，dwm 默认使用 Alt+P 打开。
download_source "dmenu" "https://git.suckless.org/dmenu"

echo
echo "准备完成，源码位置："
echo "$SUCKLESS_DIR"
echo
echo "当前只下载了依赖和源码，尚未编译安装。"
