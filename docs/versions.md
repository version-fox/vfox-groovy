# Versions

[中文](zh-CN/versions.md) | [English](versions.md)

`vfox search groovy` lists every release the Apache archive holds for Groovy, newest first. The list comes from the archive's index at `https://archive.apache.org/dist/groovy/`, so it includes releases that are no longer on the main download page.

```bash
vfox search groovy
vfox install groovy@4.0.22
```

## Names

A version is named the way Apache names its release directory:

| Kind | Example | Note in `vfox search` |
| --- | --- | --- |
| Release | `4.0.22`, `6.0.0` | none |
| Alpha, beta, release candidate | `5.0.0-alpha-10`, `6.0.0-beta-3`, `6.0.0-RC-1` | `pre-release` |
| Incubator release | `2.4.5-incubating` | `incubating` |

The versions are sorted by their numbers, then by their stage, then by the build number after the stage: `6.0.0` comes before `6.0.0-RC-3`, which comes before `6.0.0-RC-1`, and `5.0.0-alpha-10` comes before `5.0.0-alpha-2`.

Pre-releases can be installed like any other version, so `vfox install groovy@6.0.0-RC-1` works. Use `vfox use groovy@4` only where it matches what you want: vfox's fuzzy matching picks an installed version of the major.

## Incubator releases

The SDK file of an incubator release has no `-incubating` suffix: the directory `2.4.5-incubating` holds `apache-groovy-sdk-2.4.5.zip`. The plugin downloads that file, but the version keeps its name, so `vfox list groovy` shows `2.4.5-incubating`. `groovy -version` prints `Groovy Version: 2.4.5`, the version of the SDK itself.

## Checksums

Before it installs an SDK, the plugin reads the SHA-256 digest Apache publishes beside the zip (`apache-groovy-sdk-<version>.zip.sha256`), and vfox checks the download against it:

```text
Verifying checksum 17448950dea0280f708c778c43d0d1b41778ba58c5b4128a8ba1e7c0bed75bea...
Install groovy@4.0.22 success!
```

vfox verifies a download whenever Apache publishes a SHA-256 digest for it. The incubator release 2.4.5-incubating publishes an MD5 only, so it installs without a checksum, and vfox prints:

```text
WARNING: Checksum is not provided, skip verify...
```

If the digest cannot be fetched or read for a release that publishes one, the install stops with `Cannot verify the download`, so a download is never installed unchecked. Retry the install, or use a mirror that serves the digest.

## Versions that are not listed

`vfox install` refuses names the archive could not hold, such as `latest`, `../4.0.22` or `4..0`, without sending a request. It also refuses a name that the release index does not list, such as `4`, `6.0` or `9.9.9`: the install reads the index first and stops with `is not a listed release` before anything is downloaded. Copy a full name from `vfox search groovy`. See [troubleshooting](troubleshooting.md).
