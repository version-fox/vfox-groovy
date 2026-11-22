# Troubleshooting

[中文](zh-CN/troubleshooting.md) | [English](troubleshooting.md)

## `JAVA_HOME is not defined correctly`, or `cannot find javac`

Groovy's launcher needs a JDK. Set `JAVA_HOME` to a JDK home, the folder that holds `bin/java`, or put a JDK's `bin` folder with `javac` on `PATH`. On Debian and Ubuntu, a JRE alone is not enough, and the package `openjdk-21-jdk-headless` provides `javac`. The Debian `groovy` package also reads `/usr/lib/jvm/default-java`; if that link is missing, create it:

```bash
sudo ln -s /usr/lib/jvm/java-21-openjdk-amd64 /usr/lib/jvm/default-java
```

## `groovy: command not found` after `vfox use`

`vfox use` changes the version, but the shell has to load it. Add the activation to your shell profile, for example `eval "$(vfox activate bash)"` for bash and zsh, or `vfox activate pwsh | Out-String | Invoke-Expression` for PowerShell, and open a new shell. For the current shell only, run `eval "$(vfox env -s bash)"`, or in PowerShell `vfox env -s pwsh | Out-String | Invoke-Expression`.

## `Invalid Groovy version`

The plugin takes the names `vfox search groovy` lists, such as `4.0.22` or `6.0.0-RC-1`. Words such as `latest` are not versions. Use `vfox search groovy` and copy a name from it.

## `is not a listed release`

The version name is not one the archive lists, such as `4`, `6.0` or `9.9.9`, so there is no SDK to install. Use `vfox search groovy` and copy a full name from it, such as `4.0.33` or `6.0.0`. The install checks the name against the release index, so a mirror must serve that index too (see [mirror](mirror.md)).

## `failed to read the Groovy release index`

The plugin could not read `https://archive.apache.org/dist/groovy/` (or the mirror in `VFOX_GROOVY_MIRROR`). The message names the URL and the reason. Check the connection with `curl -I https://archive.apache.org/dist/groovy/`, or use a mirror (see [mirror](mirror.md)).

If the URL answers but lists no release, the message ends with `no release is listed`. The connection works; the URL does not serve the layout of the archive (see [mirror](mirror.md)), so check the mirror rather than the network.

## `no available version` after upgrading

Plugin v0.1.1 could store an empty version list in vfox's cache when the archive index had no release. vfox keeps that list for a while, and the fixed plugin does not clear it, so `vfox search groovy` can keep printing `no available version` after the upgrade. Delete `.available.cache` in the plugin folder, `$VFOX_HOME/plugin/groovy/` (by default `~/.vfox/plugin/groovy/`), then search again.

## `Cannot verify the download`

The plugin could not read the SHA-256 digest of a release that publishes one, so it stopped the install rather than install the download unchecked. The message names the URL and the reason, such as `status_code => 503` or a connection error. Retry the install, or use a mirror (see [mirror](mirror.md)).

A release that publishes no digest, such as 2.4.5-incubating, installs without one: vfox says `Checksum is not provided`, which is expected.

## `vfox link --detect` says the plugin cannot detect SDKs

vfox is older than 1.1.0, which added the `Detect` hook. Update vfox (`vfox --version`). Until then, link a Groovy folder by hand with `vfox link groovy@<version> <path>`.

## `vfox link --detect` finds nothing

The SDK may be in a place the plugin does not look. Link it by hand, as described in [linking system SDKs](link.md). Check that the folder holds `bin/groovy` and a core jar, `lib/groovy-<version>.jar`, and that `bin/groovy` is executable (`chmod +x bin/groovy` on Linux and macOS).

## A download fails its checksum

vfox refuses to install a zip whose SHA-256 does not match. Delete the cached zip under `$VFOX_HOME/cache/groovy` (by default `~/.vfox/cache/groovy`), and install again. If the same version fails again, report it: the archive may have changed, or the mirror may serve a different file.

## PowerShell: `vfox use` works, but `groovy` still runs the old version

Load the environment again in the same session with `vfox env -s pwsh | Out-String | Invoke-Expression`, or add the activation line to your profile (see above). Each new PowerShell session starts from its profile.
