# Platforms

[中文](zh-CN/platforms.md) | [English](platforms.md)

The plugin itself runs wherever vfox runs. What a platform needs is a JDK, because Groovy runs on one. The plugin installs the same Groovy SDK on every platform: the zip Apache publishes.

## What is tested

| Platform | How it is tested | Where |
| --- | --- | --- |
| Linux x86_64 | Container E2E suite, Ubuntu 26.04 image | `ubuntu-latest` |
| Linux arm64 | Container E2E suite, Ubuntu 26.04 image | `ubuntu-26.04-arm` |
| Windows x86_64 | Native E2E suite, with pwsh | `windows-latest` |
| Windows arm64 | Native E2E suite, with pwsh | `windows-11-arm` |
| macOS | Offline hook tests, with the macOS roots of `vfox link --detect` | Linux runner, mocked platform |

The offline hook tests (`vfox plugin test .`) run on Linux for every platform: they change `RUNTIME.osType` and the environment, so the Windows and macOS paths are checked without those systems. The E2E suites exercise the real systems. macOS has no E2E suite yet.

## Requirements

- vfox 0.3.0 or later to install and use the plugin.
- vfox 1.1.0 or later for `vfox link --detect groovy`.
- A JDK. Groovy's launcher finds it from `JAVA_HOME`, or from `javac` on `PATH` when `JAVA_HOME` is unset. The E2E suites use JDK 21.

## Notes per platform

- **Linux**: the Debian and Ubuntu `groovy` package installs its SDK in `/usr/share/groovy`. The launcher reads `JAVA_HOME` from `/usr/lib/jvm/default-java`, so set `JAVA_HOME` when that link does not exist. See [troubleshooting](troubleshooting.md).
- **macOS**: Homebrew keeps the SDK in `libexec` behind the `opt/groovy` link. `vfox link --detect groovy` looks there, and at Intel and Apple silicon prefixes.
- **Windows**: the SDK ships `bin\groovy.bat`, which the plugin puts on `PATH` with the other `bin` folder. Scoop, Chocolatey and folders in `Program Files` are looked at by `vfox link --detect groovy`.
