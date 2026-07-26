# mise 环境管理

本机使用 `mise` 统一管理开发语言版本。

## 安装策略

主安装入口会自动安装 mise：

```bash
~/workspace/personal/debian-desktop/prepare.sh
```

其中的 mise 安装步骤只做两件事：

1. 安装 `mise` 本体到 `~/.local/bin/mise`
2. 创建 `~/.config/mise`

它不会修改 `~/.profile` 或 `~/.bashrc`，也不会安装 Java、Node、Python、Go、Rust 等语言版本。PATH 和 Zsh 激活由仓库管理的 `shell/zshrc` 统一提供。

## 为什么不一次性安装所有语言

当前系统还处在基础桌面环境阶段。语言版本应该跟随真实项目安装：

- 需要 Java 项目时再装 Java
- 需要前端项目时再装 Node
- 需要 Python 项目时再装 Python

这样符合当前仓库的原则：少装、可解释、可回滚。

## 常用命令

查看版本：

```bash
mise --version
```

检查环境：

```bash
mise doctor
```

查看当前启用的语言版本：

```bash
mise current
```

查看可安装的 Java 版本：

```bash
mise ls-remote java
```

安装全局 Java 21：

```bash
mise install java@21
mise use -g java@21
```

在某个项目里固定 Java 21：

```bash
cd your-project
mise use java@21
```

这会在项目里生成 `.mise.toml`。

## IDEA 识别方式

推荐 IDEA 直接选择 mise 安装出来的真实 JDK 路径，而不是选择 shim。

JDK 通常位于：

```text
~/.local/share/mise/installs/java/
```

终端里用 shims 很方便：

```bash
which java
```

IDEA 里优先选择真实 JDK 目录更稳。

## 目录说明

`mise` 相关运行时目录不进入 Git：

```text
~/.local/bin/mise
~/.local/share/mise/
~/.config/mise/
```

仓库只管理安装脚本和说明文档。
