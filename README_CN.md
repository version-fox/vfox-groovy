# 简介

[English](README.md) | [中文](README_CN.md)

vfox-groovy 是一个 [vfox](https://vfox.lhan.me/) 插件，用于安装和切换 [Apache Groovy](https://groovy.apache.org/) SDK。

安装和使用 SDK 需要 vfox 0.3.0 或更高版本；`vfox link --detect` 用于接入机器上已经安装的 Groovy SDK，需要 vfox 1.1.0 或更高版本。

## 安装

安装 vfox 之后，添加插件并安装一个 Groovy 版本：

```bash
vfox add groovy
vfox search groovy
vfox install groovy@4.0.22
vfox use --global groovy@4.0.22
```

Groovy 运行在 Java 开发工具包（JDK）上，插件不会安装 JDK。请先安装 JDK，然后把 `JAVA_HOME` 设为它，或者把它的 `javac` 放进 `PATH`。

## 插件的功能

- **列出所有版本**：`vfox search groovy` 列出 Apache 归档中的每个版本，包括标记为 `pre-release` 的 alpha、beta 和候选发布版，以及标记为 `incubating` 的孵化版。详见[版本](docs/zh-CN/versions.md)。
- **校验下载**：每个 SDK 从 `archive.apache.org` 下载，vfox 用 Apache 与之并列发布的 SHA-256 摘要校验。孵化版 2.4.5-incubating 只提供 MD5，它会在没有校验值的情况下安装，并给出提示。详见[版本](docs/zh-CN/versions.md)。
- **接入已安装的 SDK**：`vfox link --detect groovy` 可以接入 SDKMAN、Homebrew、Debian 或 Ubuntu 软件包、Scoop、Chocolatey 等方式已经装好的 Groovy SDK。详见[接入系统 SDK](docs/zh-CN/link.md)。
- **设置环境**：`GROOVY_HOME` 指向 SDK，SDK 的 `bin` 目录加入 `PATH`。

## 文档

- [版本](docs/zh-CN/versions.md)：`vfox search` 列出什么、版本如何命名、校验值。
- [平台](docs/zh-CN/platforms.md)：插件测试过的操作系统和架构。
- [接入机器上已有的 JDK 与 SDK](docs/zh-CN/link.md)
- [镜像](docs/zh-CN/mirror.md)：从 Apache 归档的其他站点下载。
- [故障排查](docs/zh-CN/troubleshooting.md)
- [开发](docs/zh-CN/development.md)：插件的目录结构，以及 lint、格式、许可证和测试检查。
- [端到端测试](docs/zh-CN/e2e.md)
- [更新日志](docs/zh-CN/changes.md)

## 发布本插件

维护者可以在默认分支上，通过 **Actions → Plugin → Run workflow** 发布。输入不带 `v` 前缀的稳定插件版本即可。共享工作流会更新 `metadata.lua`、创建版本提交和标签，并在本仓库发布 ZIP 和清单。无需本地打标签，也不需要额外的发布令牌。拉取请求只运行检查，PR 标题不会触发发布。

如果 `PLUGIN.version` 与标签一致，仍然支持推送版本标签的方式。发布失败时，重新运行原来失败的作业即可继续。

工作流跟随共享的 `@v1` 发布工具版本，升级工具不会发布本插件。打包约定见[共享工作流文档](https://github.com/version-fox/plugin-manifest-action)。
