# Development

[中文](zh-CN/development.md) | [English](development.md)

## Layout

| Path | What it holds |
| --- | --- |
| `metadata.lua` | The plugin's name, homepage, notes and minimum vfox version. The release workflow sets `version`. |
| `hooks/` | One file per vfox hook: `available`, `pre_install`, `post_install`, `env_keys`, `pre_use`, `detect`. |
| `lib/` | Shared code: `util.lua` (URLs, checksums, version order), `archive_index.lua` (the release index that `vfox search` and the install read) and `detect_groovy.lua` (system SDK scanning). |
| `tests/*_test.lua` | Offline hook tests, run by `vfox plugin test`. |
| `tests/e2e/` | The Go module of the end-to-end suites: `common`, `linux` and `windows`. |
| `docs/`, `docs/zh-CN/`, `README*.md` | The documentation, in English and Chinese. |
| `.github/workflows/` | Lint, license, test, E2E and release workflows. |
| `.devcontainer/` | The dev container, with every tool the checks pin. |
| `Injection.lua` | Type hints for the objects vfox injects. It is not loaded. |

## Checks

CI runs these checks; run them locally before you push. The versions are the pinned ones.

| Check | Command | Tool |
| --- | --- | --- |
| Lua format | `stylua --check .` | StyLua 2.5.2 (`stylua .` fixes it) |
| Lua lint | `lua-language-server --check . --checklevel=Warning` | LuaLS 3.19.1 |
| Hook tests | `vfox plugin test .` | vfox 1.1.0 |
| Go format, vet, unit tests | `cd tests/e2e && gofmt -l . && go vet ./... && GOOS=windows go vet ./... && go test -short ./...` | Go 1.27.1 |
| License headers | `license-eye header check --config .licenserc.yaml` | SkyWalking Eyes v0.9.0 |
| Workflow files | `actionlint` | actionlint 1.7.7 |
| Documentation pairs | every `docs/*.md` has `docs/zh-CN/*.md`, and `README.md` has `README_CN.md` | the `check-docs` job |
| Container E2E | `cd tests/e2e && go test -v -timeout 55m -run TestE2E ./linux` | Docker |

`vfox plugin test .` finds every `tests/**/*_test.lua` and runs each file in a VM of its own, so a new test file needs no entry anywhere. A test file calls `test.load()` from `vfox.test` once, then calls the hooks through the object it returns. `test.load` takes the platform (`os`, `arch`), the environment (`env`) and a function that answers HTTP requests (`http`). `RUNTIME.osType` can be changed to try another platform.

Lua code runs on vfox's Lua, which is Lua 5.1: no `goto`, no integer division, and no `tonumber(nil)`, which is an error there. Warnings go through `print`, and the hooks return the tables vfox expects.

## Making a change

1. Change the code and its test together. A fix gets a test that fails without it.
2. Add an entry to `docs/changes.md` under *Unreleased*, and the same entry to `docs/zh-CN/changes.md`.
3. If the change is visible to users, update the English document and its Chinese counterpart.
4. Run the checks above.

## The dev container

`.devcontainer/` builds an image with the tools pinned above: Go, StyLua, LuaLS, vfox, license-eye, actionlint and the Docker CLI. `devcontainer.json` mounts the host's Docker socket, so the E2E suites start their containers on the host daemon, the way CI does. Open the repository in a dev container, then run `cd tests/e2e && go mod download` if the post-create step did not.

## Releasing

Releases are published from the workflow in [README](../README.md#releasing-this-plugin). Do not change `PLUGIN.version` by hand in a pull request. Before the release, move the *Unreleased* entries of [the changelog](changes.md) and of [its Chinese counterpart](zh-CN/changes.md) under the heading of the new version, in a pull request, so that the release includes them.
