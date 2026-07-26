# X11 会话代理环境变量设计

## 目标

让从 dwm 会话启动的终端、浏览器和 IDE 等应用继承本机 mihomo
代理环境变量，而不只是在交互式 Zsh 中提供这些变量。

## 设计

- 在 `x11/xinitrc` 启动 mihomo 后导出大小写两套代理变量：
  `http_proxy`、`https_proxy`、`all_proxy`、`no_proxy` 及其大写形式。
- HTTP 和 HTTPS 代理指向 `http://127.0.0.1:7890`。
- ALL_PROXY 指向 `socks5://127.0.0.1:7890`。
- NO_PROXY 保持为 `127.0.0.1,localhost,::1`。
- 从 `shell/zshrc` 删除同一组变量，避免同一配置在两个文件中重复维护。
- 保留 `shell/zshrc` 中与代理无关的现有本地改动，不纳入本次修改。

## 生效范围

代理变量由 `x11/xinitrc` 导出后，dwm 及其启动的子进程都会继承。
已经运行的 X11 会话不会动态更新，需要退出当前会话并重新执行
`startx`。不读取这些环境变量的程序仍可能直连；本方案不提供 TUN
透明代理。

## 验证

- 使用 `sh -n x11/xinitrc` 检查语法。
- 增加源码测试，验证代理变量位于 `x11/xinitrc`，且不再由
  `shell/zshrc` 维护。
- 运行完整测试集与 `git diff --check`。
- 重启 X11 会话后，从 dwm 启动的终端中检查代理环境变量，并验证
  Chrome 的实际联网行为。
