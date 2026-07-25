# Polybar 顶部空隙调整设计

## 目标

让 Polybar 紧贴显示器顶部，不保留透明空隙，同时保留状态栏底部现有的
4px 透明留白。

## 变更

修改 `polybar/config.ini` 中 `[bar/main]` 的顶部边框，并同步已有的配置回归测试：

- 将 `border-top-size` 从 `4px` 改为 `0`。
- 保持 `border-bottom-size = 4px`。
- 保持 `offset-y = 0`、状态栏高度及其他样式不变。
- 更新 `tests/polybar_layered_label_source_test.sh`，让断言表达新的顶部无空隙要求。

## 验证

- 确认配置仍明确设置 `border-top-size = 0`。
- 确认底部边框仍为 `4px`。
- 执行 `git diff --check`。
- 重启 Polybar 后，在真实 dwm 会话中确认状态栏紧贴屏幕顶边。
