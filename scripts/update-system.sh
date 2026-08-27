#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

APT_GET_BIN=${APT_GET_BIN:-apt-get}
DKMS_BIN=${DKMS_BIN:-/usr/sbin/dkms}
DEPMOD_BIN=${DEPMOD_BIN:-/usr/sbin/depmod}
DPKG_QUERY_BIN=${DPKG_QUERY_BIN:-dpkg-query}
READLINK_BIN=${READLINK_BIN:-readlink}
SUDO_BIN=${SUDO_BIN:-sudo}
UNAME_BIN=${UNAME_BIN:-uname}
MIHOMO_START_BIN=${MIHOMO_START_BIN:-"$REPO_DIR/mihomo/start.sh"}
VMLINUX_LINK=${VMLINUX_LINK:-/vmlinuz}
MODULES_DIR=${MODULES_DIR:-/lib/modules}
proxy_url=${APT_PROXY_URL:-http://127.0.0.1:7890}
use_proxy=1

usage() {
    cat <<EOF
用法：${0##*/} [--direct | --proxy URL]

更新 Debian 系统，并确保最新内核同时具备 headers 和 NVIDIA DKMS 模块。

  --proxy URL  使用指定的 APT HTTP 代理（默认：http://127.0.0.1:7890）
  --direct     不启动 Mihomo，APT 直接连接软件源
  -h, --help   显示帮助
EOF
}

while (($# > 0)); do
    case "$1" in
        --proxy)
            if (($# < 2)) || [[ -z $2 ]]; then
                printf 'update-system: --proxy 缺少 URL\n' >&2
                exit 2
            fi
            proxy_url=$2
            use_proxy=1
            shift 2
            ;;
        --direct)
            use_proxy=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'update-system: 未知参数：%s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

require_command() {
    local command_path=$1

    if [[ $command_path == */* ]]; then
        [[ -x $command_path ]]
    else
        command -v "$command_path" >/dev/null 2>&1
    fi
}

for required_command in \
    "$APT_GET_BIN" \
    "$DPKG_QUERY_BIN" \
    "$READLINK_BIN" \
    "$SUDO_BIN" \
    "$UNAME_BIN" \
    find grep
do
    if ! require_command "$required_command"; then
        printf 'update-system: 缺少命令：%s\n' "$required_command" >&2
        exit 1
    fi
done

apt_options=(-o Acquire::Retries=3)
if ((use_proxy)); then
    case "$proxy_url" in
        http://*|https://*) ;;
        *)
            printf 'update-system: APT 代理必须是 HTTP(S) URL：%s\n' "$proxy_url" >&2
            exit 2
            ;;
    esac
    if [[ ! -x $MIHOMO_START_BIN ]]; then
        printf 'update-system: Mihomo 启动脚本不可执行：%s\n' "$MIHOMO_START_BIN" >&2
        exit 1
    fi
    "$MIHOMO_START_BIN"
    apt_options+=(
        -o "Acquire::http::Proxy=$proxy_url"
        -o "Acquire::https::Proxy=$proxy_url"
    )
    printf 'update-system: APT 使用代理 %s\n' "$proxy_url"
else
    printf '%s\n' 'update-system: APT 使用直连'
fi

run_apt() {
    "$SUDO_BIN" "$APT_GET_BIN" "${apt_options[@]}" "$@"
}

# 提前取得 sudo 凭据，避免在耗时升级流程中间才出现密码提示。
"$SUDO_BIN" -v

printf '%s\n' '==> 更新 Debian 软件包索引'
run_apt update

# 三个元包必须共同保留：内核元包引入最新内核，headers 元包让 DKMS 能为
# 同一内核编译模块，NVIDIA 元包保留完整的 Xorg、用户态库和 DKMS 驱动。
printf '%s\n' '==> 确保内核、headers 与 NVIDIA 驱动元包已安装'
run_apt install --no-install-recommends \
    linux-image-amd64 \
    linux-headers-amd64 \
    nvidia-driver

# 不使用 -y：完整升级可能新增或删除软件包，必须让用户先审阅 APT 计划。
printf '%s\n' '==> 执行完整系统升级（确认前请检查 APT 的变更列表）'
run_apt full-upgrade

for required_package in linux-image-amd64 linux-headers-amd64 nvidia-driver; do
    package_status=$(
        "$DPKG_QUERY_BIN" -W -f='${db:Status-Abbrev}' "$required_package" \
            2>/dev/null || true
    )
    if [[ $package_status != ii* ]]; then
        printf 'update-system: 升级后缺少必要软件包：%s\n' "$required_package" >&2
        exit 1
    fi
done

kernel_image=$($READLINK_BIN -f "$VMLINUX_LINK")
target_kernel=${kernel_image##*/}
if [[ $target_kernel != vmlinuz-* ]]; then
    printf 'update-system: 无法从 %s 识别最新内核：%s\n' \
        "$VMLINUX_LINK" "$kernel_image" >&2
    exit 1
fi
target_kernel=${target_kernel#vmlinuz-}

if [[ ! -e $MODULES_DIR/$target_kernel/build ]]; then
    printf 'update-system: 最新内核缺少 headers：%s\n' "$target_kernel" >&2
    exit 1
fi
if ! require_command "$DKMS_BIN"; then
    printf 'update-system: 安装后仍缺少 DKMS：%s\n' "$DKMS_BIN" >&2
    exit 1
fi
if ! require_command "$DEPMOD_BIN"; then
    printf 'update-system: 缺少 depmod：%s\n' "$DEPMOD_BIN" >&2
    exit 1
fi

printf '==> 为最新内核重建 DKMS 模块：%s\n' "$target_kernel"
"$SUDO_BIN" "$DKMS_BIN" autoinstall -k "$target_kernel"
"$SUDO_BIN" "$DEPMOD_BIN" -a "$target_kernel"

dkms_status=$($DKMS_BIN status)
printf '%s\n' "$dkms_status"
nvidia_dkms_ready=0
while IFS= read -r status_line; do
    if [[ $status_line == nvidia-current/* ]] \
        && [[ $status_line == *", $target_kernel, "* ]] \
        && [[ $status_line == *': installed' ]]
    then
        nvidia_dkms_ready=1
        break
    fi
done <<<"$dkms_status"

if ((nvidia_dkms_ready == 0)); then
    printf 'update-system: NVIDIA DKMS 未成功安装到最新内核：%s\n' \
        "$target_kernel" >&2
    exit 1
fi

nvidia_module=$(
    find "$MODULES_DIR/$target_kernel/updates/dkms" \
        -maxdepth 1 -type f -name 'nvidia-current.ko*' -print -quit \
        2>/dev/null || true
)
if [[ -z $nvidia_module ]]; then
    printf 'update-system: 最新内核缺少 NVIDIA 模块文件：%s\n' \
        "$target_kernel" >&2
    exit 1
fi

running_kernel=$($UNAME_BIN -r)
printf '\n%s\n' '系统升级和内核模块检查完成。'
printf '当前内核：%s\n最新内核：%s\n' "$running_kernel" "$target_kernel"
if [[ $running_kernel != "$target_kernel" ]]; then
    printf '%s\n' '请保存工作后重启；新内核成功进入 dwm 前不要执行 apt autoremove。'
else
    printf '%s\n' '当前已运行最新内核；本次不需要重启来切换内核。'
fi
