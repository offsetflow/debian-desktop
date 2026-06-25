#!/usr/bin/env bash

# 任意命令失败时立即停止；未定义变量也视为错误。
set -eu

# 本脚本只安装 mise 本体，不安装 Java、Node、Python 等语言版本。
# 语言版本应在真正需要某个项目时再安装，避免把新系统变成杂货铺。

MISE_BIN="$HOME/.local/bin/mise"
PROFILE="$HOME/.profile"
BASHRC="$HOME/.bashrc"

echo "==> 检查基础命令"
command -v curl >/dev/null 2>&1 || {
    echo "缺少 curl，请先执行：sudo apt install curl ca-certificates" >&2
    exit 1
}

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/mise"
touch "$HOME/.config/mise/config.toml"

if [ -x "$MISE_BIN" ]; then
    echo "==> mise 已存在，跳过安装：$MISE_BIN"
else
    echo "==> 安装 mise 到用户目录：$MISE_BIN"

    # 使用 mise 官方安装入口。
    # MISE_INSTALL_PATH 指定到用户目录，避免写入 /usr/local/bin。
    curl -fsSL https://mise.run | MISE_INSTALL_PATH="$MISE_BIN" sh
fi

ensure_block() {
    file="$1"
    marker="$2"
    content="$3"

    touch "$file"

    if grep -Fq "$marker" "$file"; then
        echo "==> $file 已包含 mise 配置，跳过追加"
        return
    fi

    {
        printf '\n'
        printf '%s\n' "$content"
    } >> "$file"

    echo "==> 已写入 mise 配置：$file"
}

ensure_block "$PROFILE" "# >>> debian-desktop mise path >>>" '# >>> debian-desktop mise path >>>
# 让登录会话、startx 以及从图形环境启动的程序能找到 mise 和它的 shims。
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
# <<< debian-desktop mise path <<<'

ensure_block "$BASHRC" "# >>> debian-desktop mise activate >>>" '# >>> debian-desktop mise activate >>>
# 交互式 Bash 自动激活 mise；这样进入项目目录时会自动切换 .mise.toml 指定的版本。
if [ -x "$HOME/.local/bin/mise" ]; then
    eval "$("$HOME/.local/bin/mise" activate bash)"
fi
# <<< debian-desktop mise activate <<<'

# 让本次脚本进程也立即具备和新终端一致的 mise 环境，便于下面做验证。
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
eval "$("$MISE_BIN" activate bash)"

echo
echo "==> mise 版本"
mise --version

echo
echo "==> mise doctor"
mise doctor

echo
echo "安装完成。重新打开终端，或执行下面命令立即生效："
echo "source ~/.bashrc"
