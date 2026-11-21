# Mirror

[中文](zh-CN/mirror.md) | [English](mirror.md)

The plugin downloads Groovy from the Apache archive, `https://archive.apache.org/dist/groovy`. Where that host is slow or out of reach, point the plugin at another copy of the archive with `VFOX_GROOVY_MIRROR`:

```bash
export VFOX_GROOVY_MIRROR=https://mirror.example.com/apache/groovy
vfox install groovy@4.0.22
```

On Windows, set it for the session or the user:

```powershell
$env:VFOX_GROOVY_MIRROR = 'https://mirror.example.com/apache/groovy'
```

## What the mirror must serve

The mirror has to keep the layout of the archive, because the plugin builds its URLs from it:

- `<mirror>/` lists the version directories, which `vfox search groovy` reads and `vfox install` checks a version against;
- `<mirror>/<version>/distribution/apache-groovy-sdk-<file version>.zip` is the SDK;
- `<mirror>/<version>/distribution/apache-groovy-sdk-<file version>.zip.sha256` is its SHA-256 digest, when Apache publishes one.

The file version drops the `-incubating` suffix of incubator releases such as 2.4.5-incubating, as the archive does (see [versions](versions.md)).

## Rules

- The value must start with `http://` or `https://`. Anything else stops `vfox search` and `vfox install` with an error that names the value.
- A trailing slash is dropped, so `https://mirror.example.com/apache/groovy/` works as well.
- A blank value counts as unset, and the archive is used.
- The mirror applies to the index, the SDK zip and its checksum. A digest that the mirror does not have (it answers 404) is handled as an absent one: the install goes on, and vfox says the download was not verified. Any other failure to read a digest stops the install.
