# 故障排查

[中文](troubleshooting.md) | [English](../troubleshooting.md)

## `JAVA_HOME is not defined correctly`，或 `cannot find javac`

Groovy 的启动脚本需要 JDK。把 `JAVA_HOME` 设为一个 JDK 目录（即包含 `bin/java` 的目录），或者把带有 `javac` 的 JDK `bin` 目录放进 `PATH`。在 Debian 和 Ubuntu 上，只装 JRE 是不够的，需要 `openjdk-21-jdk-headless` 这样的 JDK 包提供 `javac`。Debian 的 `groovy` 软件包还会读取 `/usr/lib/jvm/default-java`；如果该链接不存在，请创建它：

```bash
sudo ln -s /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/default-java
```

## `vfox use` 之后仍然提示 `groovy: command not found`

`vfox use` 改变的是版本，但 shell 需要加载它。把激活命令写进 shell 配置文件：bash 和 zsh 用 `eval "$(vfox activate bash)"`，PowerShell 用 `vfox activate pwsh | Out-String | Invoke-Expression`，然后打开新的 shell。只想作用于当前 shell，可以运行 `eval "$(vfox env -s bash)"`；PowerShell 中运行 `vfox env -s pwsh | Out-String | Invoke-Expression`。

## `Invalid Groovy version`

插件只接受 `vfox search groovy` 列出的版本名，例如 `4.0.22` 或 `6.0.0-RC-1`。`latest` 之类的词不是版本名。请用 `vfox search groovy` 查看，并复制其中的名字。

## `failed to read the Groovy release index`

插件无法读取 `https://archive.apache.org/dist/groovy/`（或 `VFOX_GROOVY_MIRROR` 指定的镜像）。错误信息中有 URL 和原因。可以用 `curl -I https://archive.apache.org/dist/groovy/` 检查连接，或者改用镜像（见[镜像](mirror.md)）。

如果地址能正常响应但没有列出任何版本，错误信息会以 `no release is listed` 结尾。连接没有问题，是该地址没有提供归档的目录结构（见[镜像](mirror.md)），应检查镜像而不是网络。

## 升级后仍然显示 `no available version`

v0.1.1 的插件在归档索引里没有版本时，可能把空的版本列表存进 vfox 的缓存，vfox 会保留这份列表一段时间。修复后的插件不会清除它，所以升级之后 `vfox search groovy` 仍可能显示 `no available version`。删除插件目录 `$VFOX_HOME/plugin/groovy/`（默认是 `~/.vfox/plugin/groovy/`）中的 `.available.cache`，然后重新搜索。

## `Cannot verify the download`

插件无法读取已发布版本的 SHA-256 摘要，因此它中止了安装，而不是在未校验的情况下安装下载的文件。错误信息中有 URL 和原因，例如 `status_code => 503` 或连接错误。请重试安装，或使用镜像（见[镜像](mirror.md)）。

没有发布摘要的版本，例如 2.4.5-incubating，会在没有校验值的情况下安装：vfox 会提示 `Checksum is not provided`，这是预期行为。


## `vfox link --detect` 提示插件无法检测 SDK

vfox 低于 1.1.0，而 `Detect` 钩子是 1.1.0 才加入的。请升级 vfox（用 `vfox --version` 查看）。升级之前，可以用 `vfox link groovy@<版本> <路径>` 手动链接 Groovy 目录。

## `vfox link --detect` 什么也没找到

SDK 可能放在插件不会查找的位置。请按[接入系统 SDK](link.md)中的说明手动链接。确认该目录包含 `bin/groovy` 以及核心 jar `lib/groovy-<版本>.jar`。

## 下载的文件校验失败

vfox 拒绝安装 SHA-256 不匹配的 zip。删除 `$VFOX_HOME/cache/groovy` 下缓存的 zip（默认是 `~/.vfox/cache/groovy`），然后重新安装。如果同一版本再次失败，请反馈：可能是归档文件发生了变化，或镜像提供了不同的文件。

## PowerShell 中 `vfox use` 成功，但 `groovy` 仍运行旧版本

在同一会话中重新加载环境：`vfox env -s pwsh | Out-String | Invoke-Expression`，或把激活命令写进配置文件（见上文）。每个新的 PowerShell 会话都从它的配置文件开始。
