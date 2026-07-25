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
    x11-xserver-utils \
    meson \
    ninja-build \
    libx11-dev \
    libx11-xcb-dev \
    libxft-dev \
    libxinerama-dev \
    libxrender-dev \
    libxcb1-dev \
    libxcb-composite0-dev \
    libxcb-damage0-dev \
    libxcb-glx0-dev \
    libxcb-image0-dev \
    libxcb-present-dev \
    libxcb-randr0-dev \
    libxcb-render0-dev \
    libxcb-render-util0-dev \
    libxcb-shape0-dev \
    libxcb-util-dev \
    libxcb-xfixes0-dev \
    libpixman-1-dev \
    libconfig-dev \
    libegl-dev \
    libgl-dev \
    libepoxy-dev \
    libpcre2-dev \
    libev-dev \
    uthash-dev \
    libfontconfig1-dev \
    libfreetype-dev \
    fonts-jetbrains-mono \
    fonts-noto-cjk \
    fonts-font-awesome \
    fcitx5 \
    fcitx5-chinese-addons \
    polybar \
    pipewire \
    pipewire-pulse \
    wireplumber \
    pavucontrol \
    pamixer \
    feh

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
# x11-xserver-utils
#   提供 xrandr；Polybar 的亮度模块用它调整当前显示器亮度。
#
# meson / ninja-build
#   用于配置和编译 Picom 源码。
#
# libx11-dev
#   X11 基础开发接口，三个 suckless 程序都需要。
#
# libx11-xcb-dev
#   Picom 在 X11 与 XCB 之间通信所需的开发库。
#
# libxft-dev
#   X11 字体渲染接口，负责绘制抗锯齿字体。
#
# libxinerama-dev
#   dwm 的多显示器支持。
#
# libxrender-dev
#   Overview 使用 XRender 抓取并缩放窗口预览图。
#
# libxcb*-dev
#   Picom 监听窗口变化、合成、损伤区域、显示器、同步和 OpenGL
#   等 X11/XCB 功能所需的开发库。
#
# libpixman-1-dev
#   Picom 的软件像素合成与图像处理库。
#
# libconfig-dev / libpcre2-dev
#   支持读取 picom.conf，以及使用正则表达式匹配窗口规则。
#
# libgl-dev / libegl-dev / libepoxy-dev
#   提供 Picom v13 动画及 OpenGL/EGL 后端所需的图形接口。
#
# libev-dev / uthash-dev
#   Picom 的事件循环和内部哈希表依赖。
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
#
# fonts-font-awesome
#   为 Polybar 提供音量、网络、电池、电源和应用标签图标。
#
# fcitx5 / fcitx5-chinese-addons
#   提供中文输入法及拼音组件；Polybar 通过 fcitx5-remote 显示和切换输入状态。
#
# polybar
#   提供可配置的 X11 状态栏，用于显示窗口标题、时间、网络和电池。
#   APT 会自动安装它运行所必需的图形与音频库。
#
# pipewire
#   现代 Linux 音频底层，负责实际的音频流处理。
#
# pipewire-pulse
#   提供 PulseAudio 兼容层，让 Chrome、IDE 和常见播放器能直接出声。
#
# wireplumber
#   PipeWire 会话管理器，负责默认输出设备、输入设备和设备切换。
#
# pavucontrol
#   图形音量控制面板，适合在 dwm 中临时调整应用音量和输出设备。
#
# pamixer
#   命令行音量控制工具，适合绑定到 dwm 的音量快捷键。
#
# feh
#   轻量 X11 图片工具，用于在启动 dwm 时设置单屏或多屏壁纸。
#   设置完成后无需常驻后台。

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
