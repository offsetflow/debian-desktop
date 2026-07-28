# dwm 与 Neovim 快捷键速查

当前 `MODKEY` 是 `Alt`。

## 启动、选择与退出

| 快捷键 | 功能 |
|---|---|
| `Alt + Shift + Enter` | 打开 `st` 终端 |
| `Alt + P` | 打开 `dmenu` 程序启动器 |
| `Alt + E` | 打开 `Thunar` 文件管理器 |
| `Alt + Shift + P` | 选择 Mihomo 策略组和节点 |
| `Alt + Shift + W` | 预览并选择桌面壁纸 |
| `Alt + Shift + C` | 关闭当前窗口 |
| `Alt + Shift + Q` | 退出 dwm |
| `Alt + B` | 显示或隐藏 Polybar |

## 窗口操作

| 快捷键 | 功能 |
|---|---|
| `Alt + J` | 聚焦下一个窗口 |
| `Alt + K` | 聚焦上一个窗口 |
| `Alt + Enter` | 将当前窗口提升为左侧主窗口 |
| `Alt + Shift + F` | 切换当前窗口的平铺/浮动状态 |
| `Alt + H` | 缩小左侧主区域 |
| `Alt + L` | 放大左侧主区域 |
| `Alt + I` | 增加主区域窗口数量 |
| `Alt + D` | 减少主区域窗口数量 |

新打开的窗口默认追加到右侧栈区，不会替换左侧主窗口。

## 布局

| 快捷键 | 功能 |
|---|---|
| `Alt + T` | Tile：左侧主窗口，右侧纵向栈 |
| `Alt + F` | Floating：自由浮动布局 |
| `Alt + M` | Monocle：当前窗口铺满可用区域 |
| `Alt + Shift + Space` | Magic Grid：自适应网格布局 |
| `Alt + Space` | 在最近使用的两个布局之间切换 |

## 窗口间距

| 快捷键 | 功能 |
|---|---|
| `Alt + G` | 开关窗口间距 |
| `Alt + Ctrl + =` | 所有间距增加 2px |
| `Alt + Ctrl + -` | 所有间距减少 2px |

默认内外间距都是 `10px`。只有一个平铺窗口时，Smart Gaps 会取消外边距。

## Overview 窗口总览

| 快捷键 | 功能 |
|---|---|
| `Alt + A` | 打开当前显示器所有标签的窗口总览 |
| `Alt + Tab` | 在预览窗口之间轮换 |
| `Alt + A` | 选择当前预览并退出 |
| `鼠标悬停` | 选择预览窗口 |
| `鼠标左键` | 打开选中的预览窗口 |
| `Esc` | 取消并退出 Overview |

Overview 只显示当前显示器上的窗口，不混入另一块显示器。

## 标签（工作区）

下面的 `N` 代表数字 `1` 到 `9`。

| 快捷键 | 功能 |
|---|---|
| `Alt + N` | 切换到标签 N |
| `Alt + Ctrl + N` | 将标签 N 加入或移出当前视图 |
| `Alt + Shift + N` | 将当前窗口移动到标签 N |
| `Alt + Ctrl + Shift + N` | 为当前窗口追加或移除标签 N |
| `Alt + 0` | 同时显示所有标签 |
| `Alt + Shift + 0` | 让当前窗口出现在所有标签 |
| `Alt + Tab` | 返回上一个标签视图 |

Polybar 上也可以点击工作区进行切换。

## 多显示器

| 快捷键 | 功能 |
|---|---|
| `Alt + ,` | 聚焦左侧/上一台显示器 |
| `Alt + .` | 聚焦右侧/下一台显示器 |
| `Alt + Shift + ,` | 将当前窗口移动到左侧/上一台显示器 |
| `Alt + Shift + .` | 将当前窗口移动到右侧/下一台显示器 |

## 鼠标操作

| 操作 | 功能 |
|---|---|
| `Alt + 左键拖动窗口` | 移动窗口 |
| `Alt + 右键拖动窗口` | 调整窗口大小 |
| `Alt + 中键点击窗口` | 切换平铺/浮动状态 |

Polybar 已替代 dwm 原生栏，因此原生栏专用的鼠标操作通常不会使用。

## Neovim

Neovim 的 `<Leader>` 是空格键。下面用 `Space` 表示。

### 常用编辑

| 快捷键 | 功能 |
|---|---|
| `<Space>w` | 保存当前文件 |
| `<Space>q` | 退出当前窗口 |
| `<Esc>` | 清除搜索高亮 |
| `<C-h>` | 聚焦左侧分屏 |
| `<C-j>` | 聚焦下方分屏 |
| `<C-k>` | 聚焦上方分屏 |
| `<C-l>` | 聚焦右侧分屏 |

### 文件与文本搜索

| 快捷键 | 功能 |
|---|---|
| `<Space>ff` | 搜索项目文件 |
| `<Space>fg` | 搜索项目文本 |
| `<Space>fb` | 搜索并切换 Buffer |

### 编译与 Quickfix

| 快捷键 | 功能 |
|---|---|
| `<Space>m` | 执行 `:make` |
| `<Space>qo` | 打开 Quickfix 列表 |
| `<Space>qc` | 关闭 Quickfix 列表 |
| `[q` | 跳到上一条 Quickfix 结果 |
| `]q` | 跳到下一条 Quickfix 结果 |

### Git

这些快捷键只在 Git 仓库中的文件上生效。

| 快捷键 | 功能 |
|---|---|
| `[h` | 跳到上一个 Git 修改块 |
| `]h` | 跳到下一个 Git 修改块 |
| `<Space>gp` | 预览当前 Git 修改块 |
| `<Space>gb` | 查看当前行的 Git Blame |

### LSP

这些快捷键只在当前文件已经连接 Language Server 时生效。Language Server
由具体开发环境提供，Neovim 配置不会负责安装。

| 快捷键 | 功能 |
|---|---|
| `gd` | 跳到定义 |
| `gr` | 查找引用 |
| `K` | 查看符号文档 |
| `[d` | 跳到上一个诊断 |
| `]d` | 跳到下一个诊断 |
| `<Space>e` | 显示当前诊断详情 |
| `<C-x><C-o>` | 触发 LSP 补全 |

### Markdown

| 快捷键 | 功能 |
|---|---|
| `<Space>mp` | 在浏览器中打开 Markdown 实时预览 |

## 重新编译安装

修改 `suckless/dwm/config.h` 或 `dwm.c` 后：

```bash
cd ~/workspace/personal/debian-desktop
make -C suckless/dwm clean
make -C suckless/dwm
sudo make -C suckless/dwm install
```

退出并重新启动 dwm 后生效：

```text
Alt + Shift + Q
startx
```
