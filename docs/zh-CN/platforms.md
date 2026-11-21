# 平台

[中文](platforms.md) | [English](../platforms.md)

插件本身可以在 vfox 能运行的任何地方使用。平台真正需要的是 JDK，因为 Groovy 运行在 JDK 上。插件在所有平台上安装的都是 Apache 发布的同一个 SDK zip。

## 测试覆盖

| 平台 | 测试方式 | 运行环境 |
| --- | --- | --- |
| Linux x86_64 | 容器端到端测试，Ubuntu 26.04 镜像 | `ubuntu-latest` |
| Linux arm64 | 容器端到端测试，Ubuntu 26.04 镜像 | `ubuntu-26.04-arm` |
| Windows x86_64 | 原生端到端测试，使用 pwsh | `windows-latest` |
| Windows arm64 | 原生端到端测试，使用 pwsh | `windows-11-arm` |
| macOS | 离线 Hook 测试，覆盖 `vfox link --detect` 的 macOS 路径 | Linux 运行器，模拟平台 |

离线 Hook 测试（`vfox plugin test .`）在 Linux 上运行，覆盖所有平台：测试会修改 `RUNTIME.osType` 和环境变量，因此无需真的在 Windows 或 macOS 上就能检查它们的路径逻辑。端到端测试则在真实系统上运行。macOS 目前还没有端到端测试套件。

## 要求

- vfox 0.3.0 或更高版本，用于安装和使用插件。
- vfox 1.1.0 或更高版本，用于 `vfox link --detect groovy`。
- 一个 JDK。Groovy 的启动脚本优先读取 `JAVA_HOME`；未设置时使用 `PATH` 上的 `javac`。端到端测试使用 JDK 21。

## 各平台说明

- **Linux**：Debian 和 Ubuntu 的 `groovy` 软件包把 SDK 装在 `/usr/share/groovy`。启动脚本从 `/usr/lib/jvm/default-java` 读取 `JAVA_HOME`，如果该链接不存在，请自行设置 `JAVA_HOME`。见[故障排查](troubleshooting.md)。
- **macOS**：Homebrew 把 SDK 放在 `opt/groovy` 链接之后的 `libexec` 中。`vfox link --detect groovy` 会查找那里，以及 Intel 与 Apple 芯片的前缀目录。
- **Windows**：SDK 自带 `bin\groovy.bat`，插件把它所在的 `bin` 目录加入 `PATH`。`vfox link --detect groovy` 会查看 Scoop、Chocolatey 以及 `Program Files` 下的文件夹。
