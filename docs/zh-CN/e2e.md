# 端到端测试

[中文](e2e.md) | [English](../e2e.md)

端到端测试套件使用真实的 vfox 安装真实的 Groovy 版本，并检查用户实际看到的结果。测试代码位于 `tests/e2e`，这是一个只使用标准库的 Go 模块。

## 每个版本检查什么

对 `common.Versions` 中的每个版本（`4.0.22`、`2.4.5-incubating` 和 `6.0.0`），一次运行会用 vfox 1.1.0 执行以下步骤：

1. `vfox add groovy --source` 添加从本仓库构建的插件，`vfox info groovy` 的 notes 中指向 README。
2. `vfox search groovy` 列出该版本，并且 `6.0.0` 排在 `6.0.0-RC-1` 之前。
3. `vfox install groovy@<版本>` 成功；如果 Apache 提供了 SHA-256，则校验下载；如果没有，则明确提示。
4. `vfox use --global` 选中该版本，`groovy -version` 打印其 SDK 版本；`groovy -e 'println 6*7'` 输出 `42`，`GROOVY_HOME` 指向 vfox 的 `sdks` 目录。
5. `vfox link --detect -y groovy` 接入系统 SDK（Linux 上是 Debian 软件包 `/usr/share/groovy`），`vfox list` 将其标记为已链接，并且该版本以解析到该目录的 `GROOVY_HOME` 运行。
6. 第二次检测不会再链接任何新内容，也不会提供 vfox 自己安装的版本。
7. `vfox uninstall` 删除链接，系统软件包的文件保持不变。

Windows 套件的步骤相同，但系统 SDK 部分不同：Windows 上没有 Groovy 软件包，因此它通过 `GROOVY_HOME` 链接一个自己写入的 SDK 目录（版本 `9.9.9`），并检查卸载之后该目录仍然存在。

## Linux：每个版本一个容器

`tests/e2e/linux/Dockerfile` 构建一个 Ubuntu 26.04 镜像，其中包含 JDK 21、Debian 的 `groovy` 软件包和 vfox 1.1.0（x86_64 和 aarch64 都按 SHA-256 校验）。每个版本在各自的容器中运行，测试结束后容器即被删除。

在装有 Docker 的主机上本地运行：

```bash
cd tests/e2e
go test -v -timeout 55m -run TestE2E ./linux
```

第一次运行会构建镜像，需要几分钟。每个版本都要下载自己的 SDK 压缩包，大小从约 60 MB（4.0.22）到约 120 MB（6.0.0）不等，因此完整运行需要网络。

## Windows：原生运行，使用 pwsh

Windows 套件在 Windows 主机上直接运行，不使用容器。它需要 `vfox` 和 `pwsh` 位于 `PATH` 中，并且 `JAVA_HOME` 指向 JDK 21：

```powershell
cd tests\e2e
go test -v -timeout 55m -run TestE2E .\windows
```

每个版本使用自己的主目录：测试把 `USERPROFILE`（和 `HOME`）设为一个临时目录，测试结束时删除，因此任何一次运行都看不到其他运行的安装。

## CI

`.github/workflows/e2e.yml` 在 `ubuntu-latest` 和 `ubuntu-26.04-arm` 上运行 Linux 套件，在 `windows-latest` 和 `windows-11-arm` 上运行 Windows 套件。Windows 作业从 vfox 的发布页安装 vfox，校验压缩包的 SHA-256，并通过 `actions/setup-java` 安装 Temurin 21。拉取请求的新提交会取消被替代的运行；`main` 上的每次提交各自保留运行结果。

## 跳过

`go test -short ./...` 会跳过两个套件，只运行 `tests/e2e/common` 的单元测试，这些测试既不需要 Docker，也不需要网络。
