#!/usr/bin/env bash
set -euo pipefail

for required_command in sudo apt-get; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'prepare-desktop: missing command: %s\n' "$required_command" >&2
        exit 1
    fi
done

# X11 会话运行依赖：提供 X Server、输入设备、startx、显示器配置和
# 最小桌面环境中缺失的 D-Bus 会话启动工具。
x11_runtime=(
    xserver-xorg-core
    xserver-xorg-input-libinput
    xinit
    x11-xserver-utils
    dbus-x11
)

# 桌面运行依赖：状态栏、中文输入法、现代音频栈、音量控制和壁纸。
desktop_runtime=(
    polybar
    fcitx5
    fcitx5-chinese-addons
    pipewire
    pipewire-pulse
    wireplumber
    pavucontrol
    pamixer
    feh
)

# 桌面字体：终端与界面字体、CJK 回退字体和 Polybar 图标字体。
fonts=(
    fonts-jetbrains-mono
    fonts-noto-cjk
    fonts-font-awesome
)

# 通用编译工具：用于构建 suckless 项目和仓库内 Picom。
build_tools=(
    build-essential
    pkg-config
    meson
    ninja-build
)

# dwm、st、dmenu 的 X11 与字体开发头文件。
suckless_headers=(
    libx11-dev
    libxft-dev
    libxinerama-dev
    libxrender-dev
)

# Picom 的 X11/XCB、OpenGL、配置解析、事件循环和字体开发依赖。
picom_headers=(
    libx11-xcb-dev
    libxcb1-dev
    libxcb-composite0-dev
    libxcb-damage0-dev
    libxcb-glx0-dev
    libxcb-image0-dev
    libxcb-present-dev
    libxcb-randr0-dev
    libxcb-render0-dev
    libxcb-render-util0-dev
    libxcb-shape0-dev
    libxcb-util-dev
    libxcb-xfixes0-dev
    libpixman-1-dev
    libconfig-dev
    libdbus-1-dev
    libegl-dev
    libgl-dev
    libepoxy-dev
    libpcre2-dev
    libev-dev
    uthash-dev
    libfontconfig1-dev
    libfreetype-dev
)

printf '%s\n' "==> 更新 Debian 软件包索引"
sudo apt-get update

printf '%s\n' "==> 安装基础 dwm 桌面依赖"
sudo apt-get install --no-install-recommends -y \
    "${x11_runtime[@]}" \
    "${desktop_runtime[@]}" \
    "${fonts[@]}" \
    "${build_tools[@]}" \
    "${suckless_headers[@]}" \
    "${picom_headers[@]}"
