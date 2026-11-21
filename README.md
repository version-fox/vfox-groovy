# Introduction

[English](README.md) | [中文](README_CN.md)

vfox-groovy is a plugin for [vfox](https://vfox.lhan.me/) that installs and switches [Apache Groovy](https://groovy.apache.org/) SDKs.

It needs vfox 0.3.0 or later to install and use SDKs, and vfox 1.1.0 or later for `vfox link --detect`, which adopts Groovy SDKs already on the machine.

## Install

After installing vfox, add the plugin and install a Groovy release:

```bash
vfox add groovy
vfox search groovy
vfox install groovy@4.0.22
vfox use --global groovy@4.0.22
```

Groovy runs on a Java Development Kit, which the plugin does not install. Install a JDK, then either set `JAVA_HOME` to it or put its `javac` on `PATH`.

## What the plugin does

- **Lists every release** of the Apache archive with `vfox search groovy`, including the alpha, beta and release candidate builds, which are marked `pre-release`, and the `-incubating` releases, which are marked `incubating`. See [versions](docs/versions.md).
- **Verifies downloads.** Each SDK is downloaded from `archive.apache.org`, and vfox checks it against the SHA-256 digest Apache publishes beside it. The incubator release 2.4.5-incubating publishes an MD5 only; vfox installs it without a checksum and says so. See [versions](docs/versions.md).
- **Adopts Groovy SDKs already installed** by SDKMAN, Homebrew, the Debian or Ubuntu package, Scoop, Chocolatey and others, with `vfox link --detect groovy`. See [linking system SDKs](docs/link.md).
- **Sets the environment**: `GROOVY_HOME` points at the SDK and its `bin` folder is put on `PATH`.

## Documentation

- [Versions](docs/versions.md): what `vfox search` lists, how versions are named, and checksums.
- [Platforms](docs/platforms.md): the operating systems and architectures the plugin is tested on.
- [Using JDKs and SDKs already on the machine](docs/link.md)
- [Mirror](docs/mirror.md): downloading from another host of the Apache archive.
- [Troubleshooting](docs/troubleshooting.md)
- [Development](docs/development.md): the layout of the plugin, and the lint, format, license and test checks.
- [End-to-end tests](docs/e2e.md)
- [Changelog](docs/changes.md)

## Releasing this plugin

Maintainers can publish from **Actions → Plugin → Run workflow** on the default
branch by entering a stable plugin version without the `v` prefix. The shared
workflow updates `metadata.lua`, creates the version commit and tag, and publishes
the ZIP and manifest in this repository. No local tag or extra release token is
needed. Pull requests run checks only; PR titles do not trigger publication.

Existing version-tag pushes are supported when `PLUGIN.version` already matches
the tag. If publication fails, re-run the original failed job to resume it.

The workflow follows the shared `@v1` release-tool version. Updating the tool does
not release this plugin. See the [shared workflow documentation](https://github.com/version-fox/plugin-manifest-action)
for the package contract.
