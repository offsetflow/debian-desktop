#!/bin/sh

set -eu

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

. /etc/os-release

if [ "$ID" != "debian" ]; then
    echo "prepare-docker: only Debian is supported" >&2
    exit 1
fi

target_user=${SUDO_USER:-dev}
architecture=$(dpkg --print-architecture)

# 删除可能与 Docker 官方软件包冲突的发行版包。
conflicting_packages=
for package in docker.io docker-compose docker-doc podman-docker containerd runc; do
    if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'; then
        conflicting_packages="$conflicting_packages $package"
    fi
done

if [ -n "$conflicting_packages" ]; then
    apt-get remove -y $conflicting_packages
fi

# Docker 官方 APT 仓库依赖 HTTPS 证书和 curl。
apt-get update
apt-get install -y ca-certificates curl

# 安装 Docker 官方仓库签名密钥。
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# 使用当前 Debian 版本和 CPU 架构配置 Docker stable 仓库。
{
    echo "Types: deb"
    echo "URIs: https://download.docker.com/linux/debian"
    echo "Suites: $VERSION_CODENAME"
    echo "Components: stable"
    echo "Architectures: $architecture"
    echo "Signed-By: /etc/apt/keyrings/docker.asc"
} >/etc/apt/sources.list.d/docker.sources

# 安装 Docker Engine、CLI、containerd、Buildx 和 Compose v2 插件。
apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 启用 Docker 服务，并允许开发用户不加 sudo 使用 Docker CLI。
systemctl enable --now docker
usermod -aG docker "$target_user"

echo "Docker installation completed for $target_user."
echo "Log out and log in again before using Docker without sudo."
