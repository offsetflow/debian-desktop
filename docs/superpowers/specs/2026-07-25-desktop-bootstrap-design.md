# Debian Desktop 统一安装入口设计

## 目标

为全新安装的 Debian 提供一个统一、可重复执行的基础桌面安装入口。
仓库已经克隆到 `~/workspace/personal/debian-desktop` 后，用户只需执行：

```bash
./prepare.sh
```

脚本完成系统依赖安装、源码构建、用户级安装、配置部署和最终检查。
完成后，用户通过 `startx` 进入可用的 dwm 桌面。

## 范围

默认安装的基础桌面包括：

- X11、xinit 和 libinput；
- dwm、st、dmenu；
- Picom；
- Polybar；
- fcitx5 中文输入法；
- PipeWire、PipeWire Pulse 兼容层和 WirePlumber；
- 音量控制工具；
- JetBrains Mono、Noto CJK 和 Font Awesome 字体；
- 壁纸及双显示器支持；
- 仓库管理的 X11、Picom、Polybar 和字体配置。

默认流程不安装：

- mise 和任何语言运行时；
- Docker；
- mihomo；
- MySQL、Redis 或其他开发服务。

这些能力继续由现有独立脚本按需安装。

## 方案

采用“统一入口调度分模块脚本”的结构。

不把所有行为写进一个大型脚本，也不额外引入 Make、Ansible 等任务层。
根入口负责流程，模块脚本各自维护一种职责，并且可以单独运行和测试。

## 文件与职责

### `prepare.sh`

基础桌面的唯一公开安装入口：

1. 确认运行环境具备 APT；
2. 调用 `scripts/prepare-desktop.sh` 安装系统依赖；
3. 调用 `scripts/install-suckless.sh` 编译并安装 dwm、st、dmenu；
4. 调用 `scripts/install-picom.sh` 编译并安装 Picom；
5. 调用 `scripts/deploy.sh` 部署仓库配置；
6. 调用 `scripts/check.sh` 检查安装结果。

关键步骤失败时立即停止并保留清晰错误输出。

### `scripts/prepare-desktop.sh`

维护基础桌面的 APT 依赖清单。

- 运行 `apt-get update`；
- 使用 `sudo apt-get install --no-install-recommends` 安装依赖；
- 按运行依赖、suckless 编译依赖、Picom 编译依赖分组；
- 每组依赖以注释说明用途；
- 不下载或覆盖仓库内已经维护的源码。

现有 `scripts/prepare-suckless.sh` 中与基础桌面共用的依赖安装逻辑迁移到该脚本。
`prepare-suckless.sh` 保留其“准备上游源码”的独立用途，但不进入默认恢复流程，
因为仓库已经版本化维护 suckless 源码。

### `scripts/install-suckless.sh`

继续负责编译仓库内的 dwm、st、dmenu，并安装到 `~/.local`。
统一入口直接复用它，不重复实现编译逻辑。

### `scripts/install-picom.sh`

使用仓库内 Picom 源码：

1. 用 Meson 配置独立构建目录；
2. 用 Ninja 编译；
3. 安装到 `~/.local`。

脚本可重复执行；已有构建目录时重新配置，而不是依赖残留配置。

### `scripts/deploy.sh`

负责仓库配置到运行位置的软链接。

至少部署：

- `x11/xinitrc` → `~/.xinitrc`
- `picom/picom.conf` → `~/.config/picom/picom.conf`
- `polybar/config.ini` → `~/.config/polybar/config.ini`
- `fontconfig/fonts.conf` → `~/.config/fontconfig/fonts.conf`

部署规则：

- 自动创建缺失的父目录；
- 目标不存在时创建软链接；
- 目标已经是指向正确源文件的软链接时跳过；
- 目标是错误软链接、普通文件或目录时不覆盖，报告冲突并失败；
- 所有链接源使用仓库的实际绝对路径，不依赖固定用户名。

Polybar 和 Picom 的启动脚本仍从仓库执行，因此不额外复制配置。

### `scripts/check.sh`

在 TTY 环境即可执行的静态检查：

- `dwm`、`st`、`dmenu`、`picom`、`polybar`、`startx`、`fcitx5`
  等关键命令可用；
- PipeWire 和 WirePlumber 相关命令已安装；
- 必需配置链接存在并指向正确源文件；
- 仓库启动脚本具有执行权限；
- 检查失败时汇总缺失项并返回非零状态。

检查不要求 X11、dwm、Picom 或 PipeWire 当前正在运行。

## 可重复执行与错误处理

- 所有仓库脚本从自身位置推导仓库根目录，不依赖调用时的工作目录；
- 用户级文件安装到 `~/.local`；
- APT、Meson 和软链接部署均允许安全重复执行；
- 不覆盖用户已有普通配置；
- 不修改 secrets、订阅地址或其他敏感数据；
- 不自动启动图形会话；
- 不自动安装可选开发组件；
- 不执行 Git 提交、推送或源码下载。

## 使用流程

全新机器：

```bash
git clone <repository-url> ~/workspace/personal/debian-desktop
cd ~/workspace/personal/debian-desktop
./prepare.sh
startx
```

仓库已经存在时，安装命令只有：

```bash
./prepare.sh
```

## 验证

实现需要覆盖：

- 所有新增和修改 Shell 脚本的语法检查；
- 在临时 HOME 和替身命令环境中验证统一调用顺序；
- 验证部署脚本首次创建、重复运行和冲突拒绝；
- 验证检查脚本能报告缺失项；
- 运行现有测试，确认桌面配置没有回归；
- 编译 dwm、st、dmenu；
- 配置并编译 Picom；
- 执行 `git diff --check`。

测试不得写入真实 `$HOME`，也不得实际调用 APT 或 sudo。

## 提交边界

实现提交只包含统一安装入口相关文件。
工作区中已有的 dwm、Polybar、Picom 配置及其测试改动不纳入本任务提交，
除非实现过程中发现它们是完成统一安装流程不可缺少的直接依赖。
