# 使用机器上已有的 Groovy SDK

[中文](link.md) | [English](../link.md)

如果机器上已经装过 Groovy，无论是来自系统包管理器、SDKMAN、Homebrew、Scoop、Chocolatey，还是你自己解压的目录，`vfox link --detect groovy` 都会直接接入它，而不是重新下载一份。它需要 vfox 1.1.0 或更高版本（用 `vfox --version` 查看）。

```bash
vfox link --detect groovy
```

vfox 会列出插件找到的 SDK，并链接你选中的那些。`vfox link --detect -y groovy` 会不询问直接全部链接。之后 `vfox use groovy@...` 的用法不变：`vfox list groovy` 会把链接的版本标为 `(linked → <路径>)`，而 `vfox uninstall` 只删除链接，SDK 本身留在原处。

例如在 Ubuntu 上：

```bash
sudo apt-get install groovy
vfox link --detect -y groovy
vfox use --global groovy@2.4.21
```

## 会查找哪些位置

- `GROOVY_HOME` 变量指向的 SDK
- SDKMAN（`~/.sdkman/candidates/groovy`）、asdf 和 mise（`installs/groovy`）
- Homebrew：`/opt/homebrew`、`/usr/local` 和 Linuxbrew 下的 `opt/groovy/libexec`
- 系统软件包：Debian 和 Ubuntu 的 `groovy` 软件包安装的 `/usr/share/groovy`
- `/opt` 和 `/usr/local` 下名字以 `groovy` 开头的文件夹
- Windows 上：Scoop 的 `scoop\apps\groovy\current`、Chocolatey 的 `groovy\tools` 目录、`Program Files` 以及系统盘根目录下名字以 `groovy` 开头的文件夹

一个目录被认作 SDK，需要它的启动脚本能够运行（`bin/groovy` 需要有执行权限，Windows 上是 `bin\groovy.bat`），并且有核心 jar：`lib/groovy-<版本>.jar`，或者 Debian 软件包里的 `indy/groovy-<版本>-indy.jar`。旁边的模块 jar，例如 `groovy-json-<版本>.jar`，不计入。

位于 `.vfox` 目录下、或位于 `VFOX_HOME`（已设置时）下的文件夹是 vfox 自己安装的，因此不会被提供用于链接。

## 版本名

找到的 SDK 按 `vfox install` 的方式命名：即其核心 jar 的版本号，不带后缀。Debian 软件包中的 Groovy 2.4.21 名为 `2.4.21`，而 `6.0.0-RC-1` 这样的预发布版保留原名。如果多个目录是同一版本，按路径排序后的第一个会被链接，其余跳过。

## 手动链接

如果 `--detect` 没有查找的位置，可以自己指定 SDK 目录，即包含 `bin/groovy` 和 `lib` 的那个目录。vfox 在链接前会检查 `bin` 中是否有命令。

```bash
vfox link groovy@4.0.22-custom /opt/groovy-4.0.22
vfox use groovy@4.0.22-custom
```

如需让已链接的版本指向另一个目录，使用 `vfox link --force`。
