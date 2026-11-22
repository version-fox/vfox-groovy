# 更新日志

[中文](changes.md) | [English](../changes.md)

新条目记在 *Unreleased* 下。发布一个版本时，把它的条目移到以版本号和日期命名的标题下，并把 *Unreleased* 留空，供之后的改动使用。

## Unreleased

### 修复

- 归档索引中没有任何版本链接时，插件把它当作空列表返回。`vfox search groovy` 因此显示 `no available version`，vfox 还把这个空列表留在缓存里，镜像修好之后提示仍然存在。现在这种索引会报错，且不会写入缓存。
- `vfox install groovy@4`，以及归档索引中没有列出的 `groovy@6.0`、`groovy@9.9.9` 等名字，之前都以通用的下载错误失败。现在这类版本会在下载前被拒绝，错误信息指向 `vfox search groovy`。
- `vfox link --detect` 会提供接入 `bin/groovy` 没有执行权限的 Groovy 目录，然后接入失败。在 Linux 和 macOS 上，只有启动脚本能够运行的目录才会被当作 SDK。
- `vfox link --detect` 只把 `.vfox` 目录下的安装视为 vfox 自己的安装，因此自定义 `VFOX_HOME` 下的安装会被报告为已找到。现在 `VFOX_HOME` 下的目录也会被跳过。

## v0.1.1 - 2026-11-21

### 新增

- `vfox link --detect groovy` 可以接入机器上已经安装的 Groovy SDK，来源包括 SDKMAN、asdf、mise、Homebrew、Debian 和 Ubuntu 软件包、Scoop、Chocolatey 以及常见的目录。需要 vfox 1.1.0 或更高版本。见[接入系统 SDK](link.md)。
- 每个 SDK 的下载都会用 Apache 与 zip 并列发布的 SHA-256 摘要校验。孵化版 2.4.5-incubating 只提供 MD5，因此它会在没有校验值的情况下安装，并给出提示。摘要无法读取的下载不会被安装。
- `vfox search groovy` 会用 `pre-release` 标记预发布版，用 `incubating` 标记孵化版。
- `vfox info groovy` 会提示 Groovy 运行在 JDK 上，而插件不会安装 JDK，并附上 README 的链接。
- `VFOX_GROOVY_MIRROR` 可以从 Apache 归档的另一份副本下载。见[镜像](mirror.md)。
- 中英文文档：版本、平台、接入、镜像、故障排查、开发和端到端测试。
- 离线 Hook 测试（`vfox plugin test`）、Lua、Go 和工作流文件的 lint 与格式检查、许可证头检查，以及 Linux 容器和 Windows 的端到端套件，并附带对应的 CI 工作流。
- 开发容器，以及用于推送分支、创建或评论拉取请求的 `opencode.jsonc` 权限放行。

### 修复

- 预发布版排在正式版之前：`6.0.0-RC-1` 排在 `6.0.0` 前面，因为版本比较会丢弃非数字的部分。现在先按数字排序，数字相同再按阶段排序：alpha、beta、候选发布版、正式版。
- `2.4.5-incubating` 无法安装：它的 SDK 文件名没有 `-incubating` 后缀，因此下载 URL 错误。
- 读取归档索引失败时，插件抛出的是对 nil 做拼接的 Lua 错误，而不是 HTTP 状态码。错误信息中的 "parsing" 也拼写错误。
- `PreInstall` 的下载 URL 接受任意字符串作为版本。无法对应归档目录的版本现在会在发起任何请求之前被拒绝。
- `EnvKeys` 在 `ctx.path` 为空时把它当作 SDK 路径。现在 `ctx.path` 为空时会回退到 `ctx.main.path`。
