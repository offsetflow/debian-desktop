# 干净的新机 Bootstrap 设计

## 目标

将仓库整理为 Debian 最小系统上的单入口、可重复基础环境安装器。新机器克隆仓库后执行 `./prepare.sh`，即可得到可启动的 dwm 桌面、统一的用户级开发工具路径和可验证的配置部署结果。

Docker 和 mihomo 保持显式可选，不由主安装入口自动启用。

## 安装边界

`prepare.sh` 按顺序完成：

1. 安装 X11、桌面运行依赖、字体和源码编译依赖。
2. 将 mise 安装到 `~/.local/bin`。
3. 从仓库源码编译 dwm、st、dmenu，并安装到 `~/.local`。
4. 从仓库源码编译 Picom，并安装到 `~/.local`。
5. 安装仓库固定版本的 OMZ。
6. 使用软链接部署仓库管理的配置。
7. 将默认 Shell 设置为 Zsh。
8. 检查命令、安装路径、软链接、OMZ 版本和默认 Shell。

安装脚本必须可重复执行。已有非仓库配置发生冲突时停止并报告，不静默覆盖。

## 配置与路径

- 仓库路径由脚本自身位置推导；仅 X11 会话和 dwm 编译配置允许使用约定的 `$HOME/workspace/personal/debian-desktop` 路径。
- 所有用户级二进制统一安装到 `~/.local/bin`。
- Picom 安装、启动和检查必须指向同一个 `~/.local/bin/picom`。
- `shell/zshrc` 使用 `$HOME`，不包含 `/home/dev` 绝对路径。
- mise 的 PATH 和 Zsh 激活由仓库管理的 `shell/zshrc` 提供。
- mise 安装脚本不修改 `~/.bashrc` 或 `~/.profile`；它只安装 mise 本体及必要的用户级目录。
- OpenCode 不属于基础环境；删除其专用 PATH。
- 仓库不管理空置的 `.Xresources`，X11 启动时仅在文件存在时加载它。

## 显示器行为

笔记本内屏仅匹配 `eDP*`、`LVDS*` 和 `DSI*`。`DP-*`、`HDMI-*` 等均视为外接输出。

- 仅有内屏时，将内屏设为主屏。
- 内屏和外屏同时存在时，将第一个外屏设为主屏，并按启动参数放在内屏左侧或右侧。
- 没有内屏时明确报错，不猜测桌面拓扑。

## suckless 配置

每个 suckless 项目只维护一个权威配置：

- `config.def.h` 是版本控制中的配置源。
- `config.h` 是构建时生成文件，不进入版本控制。
- 安装脚本在编译前从 `config.def.h` 生成 `config.h`。
- 测试直接检查权威配置和干净源码构建，避免两份配置漂移。

## 可选组件

`scripts/prepare-docker.sh` 和 `scripts/prepare-mihomo.sh` 保持独立入口，不由 `prepare.sh` 调用。

- Docker 脚本继续负责官方仓库和系统服务配置。
- mihomo 脚本在执行前检查 `curl`、`jq`、`gzip` 等命令，并在缺失时给出明确安装提示。
- 可选组件及其依赖在文档中明确说明，但不增加基础桌面不需要的系统包。

## 清理范围

删除以下不再承担运行职责的内容：

- 已被 `prepare-desktop.sh` 取代的 `scripts/prepare-suckless.sh`。
- 未被壁纸启动脚本引用的三张壁纸。
- 已完成工作的旧 `docs/superpowers/plans/` 和 `docs/superpowers/specs/` 文档。

保留本设计文档和随后生成的实施计划。`x11/xinitrc.legacy` 在部署迁移逻辑仍依赖它时保留；本次不假设所有已有机器已经迁移。

Picom 的完整 vendored 源码保留。它是当前动画和合成器定制的可复现源码，不单独裁剪上游 CI、测试或发布文件。

## 验证

自动化验证覆盖：

- 主入口的步骤顺序及 mise 安装步骤。
- mise 安装幂等且不修改 Bash 配置文件。
- Picom 安装、启动和检查使用相同路径。
- `eDP-1 + DP-1`、`eDP-1 + HDMI-1` 和仅内屏拓扑。
- suckless 只维护权威配置，三个项目均可重新编译。
- 部署脚本重复执行和配置冲突行为。
- mihomo 缺失依赖时快速失败。
- 所有 Shell 脚本语法检查。
- 全部仓库测试、suckless 编译以及 `git diff --check`。

真实图形效果仍需在 dwm 会话中人工确认；自动测试负责验证启动链、路径和配置引用。
