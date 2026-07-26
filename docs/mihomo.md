# mihomo 代理管理

本机使用 `mihomo core + YAML 配置 + shell 脚本` 替代 `clash-verge` 图形界面。

mihomo 是可选组件，不由主 `prepare.sh` 自动安装。首次使用前安装下载和解压依赖：

```bash
sudo apt-get install --no-install-recommends curl jq gzip
```

## 文件职责

```text
scripts/prepare-mihomo.sh     安装/更新 mihomo core，并在存在 /tmp/vpn 时导入订阅
mihomo/update-profile.sh      从 /tmp/vpn 下载订阅 YAML 到 ~/.config/mihomo/config.yaml
mihomo/start.sh               后台启动 mihomo
mihomo/select.sh              通过本地 API 选择策略组节点
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

`start.sh` 会通过命令行把控制器固定到 `127.0.0.1:9090`，因此订阅配置没有 `external-controller` 时也可以使用节点选择器。控制器只监听本机回环地址。

## 选择节点

在 dwm 中按：

```text
Alt + Shift + P
```

脚本会先选择 `Selector` 策略组，再使用 dmenu 选择节点。

在终端或 SSH 中直接运行时会使用 fzf：

```bash
~/workspace/personal/debian-desktop/mihomo/select.sh
```

也可以指定策略组，跳过第一层菜单：

```bash
~/workspace/personal/debian-desktop/mihomo/select.sh PROXY
```

无交互切换：

```bash
~/workspace/personal/debian-desktop/mihomo/select.sh PROXY "节点名称"
```

选择器通过 Mihomo REST API 修改当前运行状态，不会修改订阅 YAML，也不需要重启 Mihomo。
