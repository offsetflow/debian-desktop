#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# Docker daemon 不继承用户 Shell 的代理变量，显式使用本机 mihomo。
install -m 0755 -d /etc/systemd/system/docker.service.d
printf '%s\n' \
    '[Service]' \
    'Environment="HTTP_PROXY=http://127.0.0.1:7890"' \
    'Environment="HTTPS_PROXY=http://127.0.0.1:7890"' \
    'Environment="NO_PROXY=localhost,127.0.0.1,::1"' \
    >/etc/systemd/system/docker.service.d/http-proxy.conf

systemctl daemon-reload
systemctl restart docker
