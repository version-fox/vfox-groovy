# Changelog

[中文](zh-CN/changes.md) | [English](changes.md)

New entries go under *Unreleased*. When a version is released, its entries move under a heading with the version and the date, and *Unreleased* is left empty for the next changes.

## Unreleased

### Fixed

- An archive index with no release link was read as an empty list. `vfox search groovy` then printed `no available version`, and vfox kept that empty list in its cache, so the message stayed after the mirror was fixed. Such an index is now an error, and nothing is cached.
- `vfox install groovy@4`, and names such as `groovy@6.0` or `groovy@9.9.9` that the archive does not list, failed with a generic download error. A version that the release index does not list is now refused before anything is downloaded, with a message that points to `vfox search groovy`.
- `vfox link --detect` offered a Groovy home whose `bin/groovy` is not executable, and then failed to link it. On Linux and macOS a launcher counts as an SDK only when it can run.

## v0.1.1 - 2026-11-21

### Added

- `vfox link --detect groovy` adopts Groovy SDKs already on the machine, from SDKMAN, asdf, mise, Homebrew, the Debian and Ubuntu package, Scoop, Chocolatey and the usual folders. It needs vfox 1.1.0 or later. See [linking system SDKs](link.md).
- Each SDK download is verified against the SHA-256 digest Apache publishes beside the zip. The incubator release 2.4.5-incubating publishes an MD5 only, so it installs with a warning that no checksum is provided. A download whose digest cannot be read is not installed.
- `vfox search groovy` marks pre-releases with `pre-release` and incubator releases with `incubating`.
- `vfox info groovy` notes that Groovy runs on a JDK, which the plugin does not install, and points to the README.
- `VFOX_GROOVY_MIRROR` downloads from another copy of the Apache archive. See [mirror](mirror.md).
- Documentation in English and Chinese: versions, platforms, linking, mirror, troubleshooting, development and the end-to-end tests.
- Offline hook tests (`vfox plugin test`), lint and format checks for Lua, Go and workflows, a license header check, and the end-to-end suites for Linux containers and Windows, with their CI workflows.
- A dev container, and the `opencode.jsonc` permissions for pushing branches and opening or commenting on pull requests.

### Fixed

- Pre-releases were sorted above their releases: `6.0.0-RC-1` was listed before `6.0.0`, because the version comparison dropped the parts that are not numbers. Versions now sort by their numbers, then by stage: alpha, beta, release candidate, release.
- `2.4.5-incubating` could not be installed. Its SDK file has no `-incubating` suffix, so the download URL was wrong.
- A failed request for the archive index raised a Lua error about concatenating a nil value, instead of reporting the HTTP status. The message also misspelled "parsing".
- The download URL of `PreInstall` took any string as a version. Versions that could not name an archive directory are now refused before any request is made.
- `EnvKeys` used an empty `ctx.path` as the SDK path. It now falls back to `ctx.main.path` when `ctx.path` is empty.
