# Polybar 顶部空隙调整实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移除 Polybar 顶部的 4px 透明空隙，同时保留底部 4px 透明留白。

**Architecture:** 仅调整 Polybar 主栏的顶部边框尺寸。显示器偏移、栏高、底部边框和其他已有配置均保持不变。

**Tech Stack:** Polybar INI 配置、Shell 文本检查、Git diff 校验

## Global Constraints

- 只修改 `polybar/config.ini` 中的 `border-top-size`，并同步对应测试断言。
- 保持 `border-bottom-size = 4px` 和 `offset-y = 0`。
- 保留工作区中所有既有改动。
- 不自动提交、不 push。

---

### Task 1: 移除 Polybar 顶部透明边框

**Files:**
- Modify: `polybar/config.ini:24`
- Modify: `tests/polybar_layered_label_source_test.sh:17`
- Test: `tests/polybar_layered_label_source_test.sh`、配置文本断言与 `git diff --check`

**Interfaces:**
- Consumes: Polybar `[bar/main]` 的边框配置。
- Produces: 顶部边框为 0、底部边框仍为 4px 的状态栏配置。

- [ ] **Step 1: 运行变更前断言**

Run:

```bash
awk '
    /^border-top-size = 0$/ { top = 1 }
    /^border-bottom-size = 4px$/ { bottom = 1 }
    END { exit !(top && bottom) }
' polybar/config.ini
```

Expected: FAIL，因为当前 `border-top-size` 为 `4px`。

- [ ] **Step 2: 应用最小配置修改**

将：

```ini
border-top-size = 4px
```

改为：

```ini
border-top-size = 0
```

- [ ] **Step 3: 运行配置断言**

将测试中的顶部边框断言从 `4px` 更新为 `0`，并将失败提示改为
`Polybar must not leave an inset above the status bar`。

Run:

```bash
awk '
    /^border-top-size = 0$/ { top = 1 }
    /^border-bottom-size = 4px$/ { bottom = 1 }
    END { exit !(top && bottom) }
' polybar/config.ini
sh tests/polybar_layered_label_source_test.sh
```

Expected: 两项检查均 PASS，退出码为 0。

- [ ] **Step 4: 检查改动质量**

Run:

```bash
git diff --check
git diff -- polybar/config.ini
```

Expected: `git diff --check` 退出码为 0；Polybar diff 中本任务只新增 `border-top-size = 0`，不改变其他既有用户改动。

- [ ] **Step 5: 真实会话验证**

重新启动 Polybar，在 dwm 会话中确认状态栏紧贴显示器顶边，底部 4px 透明留白仍然存在。
