# End-to-end tests

[中文](zh-CN/e2e.md) | [English](e2e.md)

The end-to-end suites install real Groovy releases with a real vfox, and check what a user would see. They live in `tests/e2e`, a Go module that uses the standard library only.

## What each version checks

For every version in `common.Versions` (`4.0.22`, `2.4.5-incubating` and `6.0.0`), a run does this with vfox 1.1.0:

1. `vfox add groovy --source` adds the plugin, built from this repository, and `vfox info groovy` shows the README in the notes.
2. `vfox search groovy` lists the version, with `6.0.0` before `6.0.0-RC-1`.
3. `vfox install groovy@<version>` succeeds, verifies the download when Apache publishes a SHA-256, and says so when it does not.
4. `vfox use --global` selects the version, and `groovy -version` prints its SDK version. `groovy -e 'println 6*7'` prints `42`, and `GROOVY_HOME` points into vfox's `sdks` folder.
5. `vfox link --detect -y groovy` links the system SDK (on Linux, the Debian package at `/usr/share/groovy`), `vfox list` marks it linked, and the version runs with `GROOVY_HOME` resolved to that folder.
6. A second detection links nothing new and never offers vfox's own installs.
7. `vfox uninstall` removes the link and leaves the system package's files in place.

The Windows suite does the same, except for the system SDK: it has no Groovy package, so it links an SDK folder it writes itself (version `9.9.9`, through `GROOVY_HOME`), and checks that the folder survives the uninstall.

## Linux: a container for each version

`tests/e2e/linux/Dockerfile` builds an Ubuntu 26.04 image with a JDK 21, the Debian `groovy` package and vfox 1.1.0 (checked by its SHA-256 for x86_64 and aarch64). Each version runs in a container of its own, which is removed when the test ends.

Run it locally from a host with Docker:

```bash
cd tests/e2e
go test -v -timeout 55m -run TestE2E ./linux
```

The first run builds the image, which takes a few minutes. Each version downloads its SDK zip, from about 60 MB (4.0.22) to about 120 MB (6.0.0), so a full run needs the network.

## Windows: natively, with pwsh

The Windows suite runs on a Windows host, without containers. It needs `vfox` and `pwsh` on `PATH`, and `JAVA_HOME` set to a JDK 21:

```powershell
cd tests\e2e
go test -v -timeout 55m -run TestE2E .\windows
```

Each version runs with a home directory of its own: the suite sets `USERPROFILE` (and `HOME`) to a temporary folder, removed at the end of the test, so no run sees another run's installs.

## CI

`.github/workflows/e2e.yml` runs the Linux suite on `ubuntu-latest` and `ubuntu-26.04-arm`, and the Windows suite on `windows-latest` and `windows-11-arm`. The Windows job installs vfox from its release, checks the archive's SHA-256, and sets up Temurin 21 with `actions/setup-java`. Pull requests cancel the run they supersede; runs on `main` each keep their own.

## Skipping

`go test -short ./...` skips both suites, and runs the unit tests of `tests/e2e/common`, which need neither Docker nor the network.
