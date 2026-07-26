# Mihomo 节点选择器设计

## 目标

为轻量 dwm 环境提供不修改 YAML、不重启 Mihomo 的节点切换入口。图形会话使用 dmenu，终端和 SSH 会话使用 fzf，并支持脚本化的无交互调用。

## 控制接口

`mihomo/start.sh` 启动 Core 时显式传入：

```text
-ext-ctl 127.0.0.1:9090
```

该命令行参数覆盖订阅配置中的控制器地址，确保订阅更新不会移除节点切换能力。控制器仅监听回环地址，不暴露给局域网。本次不设置 API secret。

节点选择器默认访问 `http://127.0.0.1:9090`，并允许测试或特殊环境通过 `MIHOMO_API_URL` 覆盖。

## `mihomo/select.sh`

脚本需要 `curl` 和 `jq`，其调用形式为：

```text
select.sh
select.sh <策略组>
select.sh <策略组> <节点名称>
```

执行流程：

1. 请求 `GET /proxies`。
2. 仅收集 `type` 为 `Selector` 的策略组。
3. 未指定策略组时，让用户从 Selector 列表选择。
4. 未指定节点时，从选中策略组的 `all` 列表选择节点。
5. 使用 `PUT /proxies/<URL 编码后的策略组>` 和 JSON `{"name":"节点名称"}` 完成切换。
6. 输出最终策略组和节点名称。

交互选择规则：

- 存在非空 `DISPLAY` 且 `dmenu` 可用时使用 `dmenu -i`。
- 否则在 `fzf` 可用时使用 `fzf`.
- 两者都不可用时给出明确错误。
- 用户取消菜单时安静退出，返回成功，不执行 PUT。

错误处理：

- Core 未运行或 API 不可达时报告控制器地址。
- 没有 Selector 策略组时报告配置不支持手工节点选择。
- 指定的策略组不存在或不是 Selector 时失败。
- 指定的节点不属于策略组时失败。
- API 返回非成功状态时保留 curl 错误并返回失败。

策略组路径使用 URL 编码，节点 JSON 使用 jq 生成，避免空格、中文、引号和特殊字符破坏请求。

## dwm 集成

在 `suckless/dwm/config.def.h` 增加命令数组，启动仓库中的 `mihomo/select.sh`。绑定：

```text
Alt + Shift + P
```

脚本在 dwm 环境自动选择 dmenu。`KEYBINDINGS.md` 同步记录该快捷键。

## 依赖与文档

基础桌面已经安装 dmenu、fzf、curl 和 jq 中除 jq 外的工具。由于 mihomo 是可选组件，`jq` 继续由 Mihomo 文档要求用户安装，不加入主 `prepare.sh`。

`docs/mihomo.md` 增加交互式、终端和无交互三种用法，并说明切换只影响运行状态，不重写订阅配置。

## 测试

自动化测试覆盖：

- `start.sh` 始终传入回环地址的 `-ext-ctl`。
- 从 API 响应中过滤 Selector 策略组。
- 策略组和节点的 dmenu/fzf 选择流程。
- 直接传参切换。
- 中文及空格策略组的 URL 编码。
- 节点名称的安全 JSON 编码。
- 用户取消时不发送 PUT。
- API 不可达、无 Selector、未知组和未知节点。
- dwm 快捷键和文档引用。

最终运行验证需要在 Mihomo 已启动的 dwm 会话中按 `Alt + Shift + P`，确认菜单显示实际订阅节点并能完成切换。
