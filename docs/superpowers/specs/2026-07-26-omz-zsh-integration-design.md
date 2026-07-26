# OMZ 与 Zsh 系统集成设计

## 目标

把 `yaocccc/omz` 集成到仓库管理的 Debian 基础开发环境中。
执行根目录 `./prepare.sh` 后：

- Zsh、fzf、fd 和 Lua 依赖已安装；
- OMZ 固定版本安装到用户目录；
- 仓库管理的 Zsh 配置通过软链接部署；
- mise 和用户级命令 PATH 在 Zsh 中可用；
- `dev` 用户的默认登录 Shell 为 Zsh；
- 重复执行不会覆盖用户配置或漂移到新的 OMZ 版本。

## 上游版本

- 上游仓库：`https://github.com/yaocccc/omz.git`
- 上游分支：`master`
- 固定 commit：`3a2df05e6bff546da0d252290bbba333475ad4a0`
- 查询日期：2026-07-26

固定 commit 单独记录在 `shell/omz-version`。
普通安装只部署这个版本，不跟随 `master` 自动升级。
升级时先人工核对上游变化，再更新版本文件并运行测试。

## 方案

采用“仓库管理配置和版本，第三方源码安装到用户数据目录”的方式：

- `debian-desktop` 不复制 OMZ 第三方源码；
- OMZ Git checkout 位于 `~/.local/share/omz`；
- `.zshrc` 的唯一维护版本位于仓库 `shell/zshrc`；
- `$HOME` 只保留指向仓库配置的软链接；
- 安装、部署和检查继续复用现有 `prepare.sh` 分层结构。

不使用 Git submodule，也不在每次安装时直接跟随上游最新提交。

## 依赖

`scripts/prepare-desktop.sh` 的基础桌面依赖增加：

- `zsh`：交互式和登录 Shell；
- `fzf`：OMZ 的补全和历史搜索界面；
- `fd-find`：OMZ 文件搜索依赖；
- Debian 当前版本提供的 Lua 解释器包。

安装前通过 Debian 软件包元数据确认准确包名。
`bat`、`exa`/`eza` 和 `ueberzugpp` 属于上游可选预览增强，不进入默认安装。

## 文件与职责

### `shell/omz-version`

只包含一行完整的 40 位 Git commit。
安装脚本读取该文件，拒绝空值或格式错误的版本。

### `shell/zshrc`

仓库维护的最小 Zsh 入口：

1. 将 `~/.local/bin` 和 mise shims 加入 PATH；
2. 如果 mise 存在，执行 `mise activate zsh`；
3. 显式设置 OMZ 行为：
   - `_OMZ_APPLY_PREEXEC_HOOK=false`
   - `_OMZ_APPLY_CHPWD_HOOK=false`
   - `_OMZ_APPLY_HISTORYBYFZF=true`
4. 检查 `~/.local/share/omz/omz.zsh` 存在后再 source；
5. OMZ 缺失时输出一条可操作的错误提示，不让 Zsh 启动直接退出。

配置不包含秘密、代理订阅或机器专用值。

### `scripts/install-omz.sh`

负责固定版本安装：

1. 从自身路径解析仓库根目录；
2. 检查 `git` 和 `shell/omz-version`；
3. 目标不存在时 clone 到 `~/.local/share/omz`；
4. 目标已是正确上游 Git 仓库时 fetch 固定 commit；
5. checkout 到固定 commit 的 detached HEAD；
6. 验证 `HEAD` 与版本文件完全一致；
7. 创建 `~/.local/bin/fd` 指向系统 `fdfind` 的软链接。

安全规则：

- 目标是普通文件、非 Git 目录或其他上游仓库时失败，不覆盖；
- `fd` 已是正确链接时跳过；
- `fd` 是其他文件或链接时失败，不覆盖；
- 不修改 OMZ checkout 中的配置；
- 不执行 `git pull`，避免版本漂移。

### `scripts/set-default-shell.sh`

负责默认 Shell：

- 通过 `getent passwd "$USER"` 读取当前登录 Shell；
- 已是系统 Zsh 路径时跳过；
- 确认 Zsh 路径存在于 `/etc/shells`；
- 使用 `sudo chsh -s <zsh-path> "$USER"` 切换；
- 测试通过命令替身完成，不修改真实 `/etc/passwd`。

该动作属于用户明确批准的系统集成行为，并由根 `prepare.sh` 自动调用。

### `scripts/deploy.sh`

新增链接：

```text
shell/zshrc → ~/.zshrc
```

继续沿用现有规则：目标不存在时创建；正确链接跳过；错误链接、普通文件或目录均报告冲突并失败。

### `scripts/check.sh`

增加以下静态检查：

- `zsh`、`fzf`、`fd` 和 Lua 命令可用；
- `~/.zshrc` 指向仓库 `shell/zshrc`；
- `~/.local/share/omz` 是 Git checkout；
- OMZ `HEAD` 等于 `shell/omz-version`；
- `~/.local/bin/fd` 指向 `fdfind`；
- 当前用户默认登录 Shell 等于系统 Zsh 路径。

检查只读取状态，不联网、不修改系统。

### 根 `prepare.sh`

基础桌面流程扩展为：

1. 安装系统依赖；
2. 安装 dwm、st、dmenu；
3. 安装 Picom；
4. 安装固定版本 OMZ；
5. 部署配置；
6. 设置默认 Zsh；
7. 检查完整安装。

任何阶段失败时立即停止，不自动启动 Zsh 或 X11。

## 错误处理

- 网络或上游 Git 操作失败时保留已有正确 checkout，不删除用户数据；
- OMZ 目录来源不明时拒绝接管；
- `.zshrc` 冲突时提示用户自行迁移，不覆盖；
- 无法切换默认 Shell 时安装失败并显示具体命令；
- 上游固定 commit 不可获取时失败，不回退到 `master`；
- 所有临时测试使用独立 HOME、Git 仓库和命令替身。

## 验证

实现需要覆盖：

- OMZ 首次安装；
- 固定 commit checkout；
- 重复安装；
- 错误来源目录拒绝；
- fd 正确链接和冲突拒绝；
- `.zshrc` 首次部署、重复部署和冲突拒绝；
- 默认 Shell 已正确时跳过、需要切换时调用正确命令；
- 根安装入口的新执行顺序和失败中止；
- 检查器对版本漂移、缺失命令和默认 Shell 错误的汇总；
- 使用全新 Zsh 进程验证 `.zshrc` 语法和 mise/OMZ 加载；
- 所有仓库测试、Shell 语法检查与 `git diff --check`。

测试不得联网、调用 APT/sudo/chsh 或修改真实 HOME。

## 提交与部署边界

- 实现提交只包含 OMZ/Zsh 集成及其直接测试、文档和依赖调整；
- 不自动 push，除非用户再次明确要求；
- 不在实现阶段直接运行真实 `chsh`；切换动作由用户以后运行
  `./prepare.sh` 时发生；
- 不安装上游标记为可选的终端图片或文件预览工具。
