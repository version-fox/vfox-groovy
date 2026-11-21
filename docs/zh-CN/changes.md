# 更新日志

[中文](changes.md) | [English](../changes.md)

条目先记在 *Unreleased* 下，直到发布工作流发布一个版本；届时该版本会在自己的标题下保留这些条目。

## Unreleased

### 新增

- `vfox link --detect groovy` 可以接入机器上已经安装的 Groovy SDK，来源包括 SDKMAN、asdf、mise、Homebrew、Debian 和 Ubuntu 软件包、Scoop、Chocolatey 以及常见的目录。需要 vfox 1.1.0 或更高版本。见[接入系统 SDK](link.md)。
- 每个 SDK 的下载都会用 Apache 与 zip 并列发布的 SHA-256 摘要校验。孵化版 2.4.5-incubating 只提供 MD5，因此它会在没有校验值的情况下安装，并给出提示。
- `vfox search groovy` 会用 `pre-release` 标记预发布版，用 `incubating` 标记孵化版。
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
