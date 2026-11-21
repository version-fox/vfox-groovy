# 镜像

[中文](mirror.md) | [English](../mirror.md)

插件从 Apache 归档 `https://archive.apache.org/dist/groovy` 下载 Groovy。如果该站点速度慢或无法访问，可以用 `VFOX_GROOVY_MIRROR` 让插件改用另一份归档副本：

```bash
export VFOX_GROOVY_MIRROR=https://mirror.example.com/apache/groovy
vfox install groovy@4.0.22
```

在 Windows 上，可以为当前会话或当前用户设置：

```powershell
$env:VFOX_GROOVY_MIRROR = 'https://mirror.example.com/apache/groovy'
```

## 镜像需要提供的内容

镜像必须保持归档的目录结构，因为插件据此拼接 URL：

- `<镜像>/` 列出各版本目录，`vfox search groovy` 读取的就是它；
- `<镜像>/<版本>/distribution/apache-groovy-sdk-<文件版本>.zip` 是 SDK；
- `<镜像>/<版本>/distribution/apache-groovy-sdk-<文件版本>.zip.sha256` 是它的 SHA-256 摘要（Apache 提供时）。

与归档一样，文件版本会去掉孵化版（如 2.4.5-incubating）的 `-incubating` 后缀（见[版本](versions.md)）。

## 规则

- 值必须以 `http://` 或 `https://` 开头。其他值会让 `vfox search` 和 `vfox install` 报错，错误信息中会包含该值。
- 末尾的斜杠会被去掉，因此 `https://mirror.example.com/apache/groovy/` 同样可用。
- 空白值视为未设置，仍使用归档。
- 镜像用于索引、SDK zip 及其校验文件。镜像上没有校验文件时按没有校验值处理：安装继续，vfox 会提示下载未经校验。
