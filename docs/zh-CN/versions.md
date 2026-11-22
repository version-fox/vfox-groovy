# 版本

[中文](versions.md) | [English](../versions.md)

`vfox search groovy` 按从新到旧的顺序列出 Apache 归档中所有的 Groovy 版本。列表来自归档的索引页 `https://archive.apache.org/dist/groovy/`，因此也包含已经不在主下载页上的版本。

```bash
vfox search groovy
vfox install groovy@4.0.22
```

## 版本名

版本名与 Apache 的版本目录名相同：

| 类型 | 示例 | `vfox search` 中的备注 |
| --- | --- | --- |
| 正式版 | `4.0.22`、`6.0.0` | 无 |
| alpha、beta、候选发布版（RC） | `5.0.0-alpha-10`、`6.0.0-beta-3`、`6.0.0-RC-1` | `pre-release` |
| 孵化版（incubator） | `2.4.5-incubating` | `incubating` |

版本先按数字排序，数字相同再按阶段排序，阶段也相同时再按阶段后的编号排序：`6.0.0` 排在 `6.0.0-RC-3` 之前，`6.0.0-RC-3` 排在 `6.0.0-RC-1` 之前，`5.0.0-alpha-10` 排在 `5.0.0-alpha-2` 之前。

预发布版和其他版本一样可以安装，例如 `vfox install groovy@6.0.0-RC-1`。`vfox use groovy@4` 这类写法依赖 vfox 的模糊匹配，只在你确实想选该主版本下的已安装版本时使用。

## 孵化版

孵化版的 SDK 文件名没有 `-incubating` 后缀：目录 `2.4.5-incubating` 里的文件是 `apache-groovy-sdk-2.4.5.zip`。插件会下载这个文件，但版本名保持 `2.4.5-incubating`，所以 `vfox list groovy` 显示的是 `2.4.5-incubating`。`groovy -version` 打印的是 SDK 自身的版本 `Groovy Version: 2.4.5`。

## 校验值

安装 SDK 之前，插件会读取 Apache 与 zip 并列发布的 SHA-256 摘要（`apache-groovy-sdk-<版本>.zip.sha256`），vfox 用它校验下载的文件：

```text
Verifying checksum 17448950dea0280f708c778c43d0d1b41778ba58c5b4128a8ba1e7c0bed75bea...
Install groovy@4.0.22 success!
```

只要 Apache 为某个版本提供了 SHA-256 摘要，vfox 就会校验该下载。孵化版 2.4.5-incubating 只提供 MD5，因此它会在没有校验值的情况下安装，并且 vfox 会打印：

```text
WARNING: Checksum is not provided, skip verify...
```

如果某个发布了摘要的版本，其摘要无法获取或读取，安装会以 `Cannot verify the download` 失败，因此下载的文件绝不会在未校验的情况下安装。请重试安装，或使用提供摘要的镜像。

## 归档中没有的版本

`vfox install` 会拒绝归档里不可能存在的名字，例如 `../4.0.22` 或 `4..0`，并且不发送任何请求。对于格式合法、但发布索引中没有列出的名字，例如 `4`、`6.0` 或 `9.9.9`，安装会先读取发布索引，并在下载之前报 `is not a listed release`。请从 `vfox search groovy` 中复制完整的版本名。见[故障排查](troubleshooting.md)。

`latest` 不会被拒绝。插件运行之前，vfox 会把它换成 `vfox search groovy` 列出的第一个名字，因此 `vfox install groovy@latest` 安装的是归档中最高的版本，它可能是预发布版。
