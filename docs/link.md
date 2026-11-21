# Using Groovy SDKs that are already on the machine

[中文](zh-CN/link.md) | [English](link.md)

If Groovy is already installed — from the system package manager, SDKMAN, Homebrew, Scoop, Chocolatey or a folder you unzipped yourself — `vfox link --detect groovy` adopts it instead of downloading another copy. It needs vfox 1.1.0 or later (`vfox --version`).

```bash
vfox link --detect groovy
```

vfox lists what the plugin found and links what you pick. `vfox link --detect -y groovy` links everything without asking. Afterwards `vfox use groovy@...` works as usual: `vfox list groovy` marks linked versions `(linked → <path>)`, and `vfox uninstall` removes only the link, leaving the SDK where it is.

For example, on Ubuntu:

```bash
sudo apt-get install groovy
vfox link --detect -y groovy
vfox use --global groovy@2.4.21
```

## What it finds

- The `GROOVY_HOME` variable, when it points at an SDK
- SDKMAN (`~/.sdkman/candidates/groovy`), asdf and mise (`installs/groovy`)
- Homebrew: `opt/groovy/libexec` under `/opt/homebrew`, `/usr/local` and Linuxbrew
- The system package: `/usr/share/groovy`, which the Debian and Ubuntu `groovy` package installs
- Folders in `/opt` and `/usr/local` whose names start with `groovy`
- On Windows: Scoop's `scoop\apps\groovy\current`, Chocolatey's `groovy\tools` folder, folders in `Program Files` and in the root of the system drive whose names start with `groovy`

An SDK counts when its launcher can run (`bin/groovy` with the execute bit set, or `bin\groovy.bat` on Windows), and its core jar is there too: `lib/groovy-<version>.jar`, or `indy/groovy-<version>-indy.jar` in the Debian package. The module jars beside it, such as `groovy-json-<version>.jar`, do not count.

Folders under a `.vfox` directory, and under `VFOX_HOME` when that variable is set, are vfox's own installs, so they are never offered for linking.

## Version names

A found SDK is named the way `vfox install` names it: the number of its core jar, with no suffix. The Debian package of Groovy 2.4.21 becomes `2.4.21`, and a pre-release such as `6.0.0-RC-1` keeps its name. When several folders hold the same version, the first path in sorted order is linked and the rest are skipped.

## Linking by hand

Where `--detect` does not look, point at the SDK folder yourself: the folder that holds `bin/groovy` and `lib`. vfox checks that a command is in `bin` before it links the folder.

```bash
vfox link groovy@4.0.22-custom /opt/groovy-4.0.22
vfox use groovy@4.0.22-custom
```

Use `vfox link --force` to point an already linked version at another folder.
