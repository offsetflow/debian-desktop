# mihomo 代理管理

本机使用 `mihomo core + YAML 配置 + shell 脚本` 替代 `clash-verge` 图形界面。

## 文件职责

```text
scripts/prepare-mihomo.sh     安装/更新 mihomo core，并在存在 /tmp/vpn 时导入订阅
mihomo/update-profile.sh      从 /tmp/vpn 下载订阅 YAML 到 ~/.config/mihomo/config.yaml
mihomo/start.sh               后台启动 mihomo
mihomo/stop.sh                停止 mihomo
mihomo/status.sh              查看进程、端口和日志
```

订阅 URL 不进入 Git。默认读取：

```text
/tmp/vpn
```

运行时配置目录：

```text
~/.config/mihomo/
```

## 安装或更新 core

```bash
~/workspace/personal/debian-desktop/scripts/prepare-mihomo.sh
```

脚本会安装 Linux amd64 compatible 版：

```text
~/.local/bin/mihomo
```

## 导入订阅

把订阅 URL 写入 `/tmp/vpn`，注意不要把它提交到 Git：

```bash
printf '%s\n' '你的订阅URL' > /tmp/vpn
chmod 600 /tmp/vpn
```

然后执行：

```bash
~/workspace/personal/debian-desktop/mihomo/update-profile.sh
```

## 启动和停止

```bash
~/workspace/personal/debian-desktop/mihomo/start.sh
~/workspace/personal/debian-desktop/mihomo/status.sh
~/workspace/personal/debian-desktop/mihomo/stop.sh
```

默认代理端口取决于订阅 YAML。常见端口是：

```text
mixed-port: 7890
external-controller: 127.0.0.1:9090
```

如果订阅配置没有这些字段，可以后续再加一个固定的基础配置层。
