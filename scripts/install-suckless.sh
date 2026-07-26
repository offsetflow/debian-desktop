#!/usr/bin/env bash

# 任意命令失败时立即停止。
set -e

# 本仓库目录。
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DESKTOP_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# suckless 源码统一存放位置。
SUCKLESS_DIR="$DESKTOP_DIR/suckless"

# 用户级安装前缀。
#
# dwm、st、dmenu 属于用户级命令，统一安装到 ~/.local，
# 与 x11/xinitrc 中 `exec "$HOME/.local/bin/dwm"` 的启动路径保持一致，
# 避免出现「编译安装到 /usr/local，实际运行 ~/.local 旧二进制」的错位。
PREFIX="$HOME/.local"
MANPREFIX="$PREFIX/share/man"

# 需要编译安装的 suckless 程序。
PROGRAMS="dwm st dmenu"

for name in $PROGRAMS; do
    target="$SUCKLESS_DIR/$name"

    if [ ! -d "$target" ]; then
        echo "install-suckless: missing source directory: $target" >&2
        continue
    fi

    echo "==> 编译并安装 $name 到 $PREFIX/bin"

    # config.def.h 是唯一受版本控制的配置源；config.h 只用于本次构建。
    cp "$target/config.def.h" "$target/config.h"

    # clean 强制重新编译，确保源码改动生效；install 依赖 all 会自动构建。
    # 命令行传入的 PREFIX/MANPREFIX 会覆盖 config.mk 中的默认值。
    make -C "$target" \
        PREFIX="$PREFIX" \
        MANPREFIX="$MANPREFIX" \
        clean install
done

echo
echo "安装完成，二进制位置：$PREFIX/bin"
echo
echo "dwm 正在运行的是内存中的旧进程，需重启会话才能生效："
echo "  Mod+Shift+Q 退出 dwm，然后重新执行 startx。"
