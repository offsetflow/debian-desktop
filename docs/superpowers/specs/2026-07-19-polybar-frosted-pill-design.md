# Polybar 磨砂玻璃与圆角活动标签设计

## 目标

让现有 Polybar 接近参考图：状态栏背景透明磨砂，当前 dwm 标签显示为红色半透明圆角胶囊。保持现有动态应用名称、双屏独立标签和右侧状态模块，不修改 dwm 的窗口排列逻辑。

## 方案

### 真透明磨砂

- 关闭 Polybar 的 `pseudo-transparency`，保留带 Alpha 的 ARGB 背景色。
- Picom 对 `class_g = 'Polybar'` 开启 `dual_kawase` 背景模糊。
- 调整通用 `dock` 规则，避免它覆盖 Polybar 的模糊规则。
- Polybar 不使用阴影和窗口圆角，保持跨屏顶栏边缘稳定。

### 活动标签胶囊

- 使用 Nerd Symbols 的左、右圆角字形包裹活动标签。
- 圆角字形和标签主体使用同一红色半透明背景色，形成连续胶囊。
- 普通已占用标签保持透明；空标签继续隐藏。
- 应用名称仍由 dwm 的 EWMH desktop name 提供，标签点击行为继续由 `internal/xworkspaces` 负责。

### 字体管理

- 仅安装 Symbols Nerd Font，不替换 JetBrains Mono 正文字体。
- 字体依赖和用途记录在 `scripts/prepare-suckless.sh`。
- Polybar 将符号字体作为单独 fallback font 使用。

## 验证

- Polybar 配置解析无错误和警告。
- 两个显示器各自只有一个 Polybar，系统托盘只在主屏。
- Picom 日志无规则解析错误，Polybar 后方壁纸可见且有模糊。
- 当前标签呈圆角红色胶囊，普通标签无胶囊，空标签不显示。
- dwm 的 `tile`、`magicgrid`、gaps 和窗口几何行为不发生变化。
