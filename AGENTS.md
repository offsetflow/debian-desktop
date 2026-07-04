# Debian + dwm 开发环境管理约定

## 1. 环境定位

- 系统使用 Debian 最小化安装，不安装完整桌面环境。
- 窗口管理器使用源码管理的 dwm。
- 主用户为 `dev`。
- 桌面环境仓库：`/home/dev/workspace/personal/debian-desktop`。
- 普通开发项目：`/home/dev/workspace/playground/<project>`。
- `debian-desktop` 是桌面环境和开发环境配置的唯一事实来源。

## 2. 目录职责

```text
debian-desktop/
├── suckless/       # dwm、st、dmenu 源码
├── x11/            # X11 与图形会话配置
├── polybar/        # 状态栏配置
├── picom/          # 合成器配置
├── fcitx5/         # 输入法配置
├── mihomo/         # 代理管理脚本
├── shell/          # PATH、mise、代理等 Shell 配置
├── scripts/        # 配置部署与维护脚本
├── wallpapers/     # 壁纸
└── prepare.sh      # 系统依赖安装脚本
```

目录按职责划分，只保留实际使用的模块，不为未来可能的需求提前设计。

## 3. 配置管理

- 关键配置必须保存在 `debian-desktop` 仓库中。
- `$HOME` 中尽量只保留指向仓库配置的软链接或轻量入口。
- `.xinitrc`、Shell 配置、picom、polybar、fcitx5 等配置应由仓库统一管理。
- 软链接和配置部署应由统一脚本完成，并保证可以重复执行。
- 不在 `$HOME` 和仓库中重复维护同一份配置。
- 修改配置时先修改仓库版本，再部署到系统。

## 4. 开发环境管理

- Java、Node.js、Python 等多版本开发环境统一使用 mise 管理。
- 不使用 APT 手动安装多个语言运行时版本。
- 全局默认版本由 mise 管理，项目特殊版本写入项目自己的 mise 配置。
- mise 初始化与 PATH 配置由 `debian-desktop/shell/` 统一管理。
- 用户级命令优先安装到 `~/.local/bin`。
- 源码项目统一放到 `/home/dev/workspace/playground`，不按语言创建无意义的分类目录。

## 5. 轻量化与依赖管理

- 保持 Debian 系统轻量，不安装 GNOME、KDE 等完整桌面环境。
- 只安装当前功能确实需要的依赖，不安装用途不明确的软件包。
- 所有必要的系统依赖必须写入 `prepare.sh`，不能只在终端临时安装。
- `prepare.sh` 中每组依赖必须用注释说明用途。
- 区分运行依赖和源码编译依赖，避免重复安装。
- 添加依赖前先确认 Debian 当前版本中的有效包名。
- 删除功能时检查对应依赖是否还需要保留。

## 6. 仓库管理边界

仓库应管理：

- 可复现的配置文件。
- dwm、st、dmenu 等需要维护的源码。
- 系统依赖清单。
- 安装、部署、启动和维护脚本。
- 非敏感的配置模板。

仓库不得管理：

- 密码、SSH 私钥、API Key、Token 和代理订阅地址。
- 浏览器数据、Cookie 和用户运行状态。
- 缓存、日志、PID、数据库和编译产物。
- 模型、视频等大型运行数据。

敏感配置放在仓库外，例如：

```text
~/.config/debian-desktop/secrets.sh
```

仓库只保存不包含真实值的示例文件。

## 7. 修改与验证

开始工作前先检查：

```bash
cd /home/dev/workspace/personal/debian-desktop
git status --short
```

修改时必须保留用户已有改动，不处理当前任务之外的文件。

完成后根据改动执行必要验证：

- Shell 脚本执行语法检查。
- suckless 源码修改后重新编译。
- 软链接检查目标是否正确。
- mise、PATH 等环境配置使用新 Shell 验证。
- 图形配置在真实 dwm 会话中验证。
- 提交前执行 `git diff --check`。

未经用户明确要求，不自动提交、不 push、不删除文件，也不使用破坏性 Git 命令。

## 核心原则

> 仓库管理可复现配置，关键配置通过软链接部署；开发环境统一由 mise 管理；系统保持轻量；必要依赖统一记录在 `prepare.sh`；秘密和运行数据不进入 Git。
