# 开发

[中文](development.md) | [English](../development.md)

## 目录结构

| 路径 | 内容 |
| --- | --- |
| `metadata.lua` | 插件的名称、主页、notes 和最低 vfox 版本。发布工作流会设置 `version`。 |
| `hooks/` | 每个 vfox 钩子一个文件：`available`、`pre_install`、`post_install`、`env_keys`、`pre_use` 和 `detect`。 |
| `lib/` | 共享代码：`util.lua`（URL、校验值、版本排序）、`archive_index.lua`（`vfox search` 和安装读取的发布索引）和 `detect_groovy.lua`（系统 SDK 扫描）。 |
| `tests/*_test.lua` | 离线 Hook 测试，由 `vfox plugin test` 运行。 |
| `tests/e2e/` | 端到端测试套件的 Go 模块：`common`、`linux` 和 `windows`。 |
| `docs/`、`docs/zh-CN/`、`README*.md` | 文档，中英文成对。 |
| `.github/workflows/` | lint、许可证、测试、端到端和发布工作流。 |
| `.devcontainer/` | 开发容器，包含所有检查固定使用的工具。 |
| `Injection.lua` | vfox 注入对象的类型提示，不会被加载。 |

## 检查

CI 运行以下检查，推送之前请先在本地运行。版本号即 CI 固定的版本。

| 检查 | 命令 | 工具 |
| --- | --- | --- |
| Lua 格式 | `stylua --check .`（`stylua .` 可自动修复） | StyLua 2.5.2 |
| Lua lint | `lua-language-server --check . --checklevel=Warning` | LuaLS 3.19.1 |
| Hook 测试 | `vfox plugin test .` | vfox 1.1.0 |
| Go 格式、vet 与单元测试 | `cd tests/e2e && gofmt -l . && go vet ./... && GOOS=windows go vet ./... && go test -short ./...` | Go 1.27.1 |
| 许可证头 | `license-eye header check --config .licenserc.yaml` | SkyWalking Eyes v0.9.0 |
| 工作流文件 | `actionlint` | actionlint 1.7.7 |
| 文档成对 | 每个 `docs/*.md` 都有 `docs/zh-CN/*.md`，`README.md` 都有 `README_CN.md` | `check-docs` 作业 |
| 容器端到端测试 | `cd tests/e2e && go test -v -timeout 55m -run TestE2E ./linux` | Docker |

`vfox plugin test .` 会找到所有 `tests/**/*_test.lua`，并且每个文件在独立的虚拟机中运行，因此新增测试文件无需在别处登记。测试文件要从 `vfox.test` 调用一次 `test.load()`，然后通过它返回的对象调用各个 Hook。`test.load` 接受平台（`os`、`arch`）、环境变量（`env`）以及应答 HTTP 请求的函数（`http`）。要模拟其他平台，可以修改 `RUNTIME.osType`。

Lua 代码运行在 vfox 的 Lua 上，即 Lua 5.1：不能使用 `goto`，没有整数除法，而 `tonumber(nil)` 在这里会报错。警告通过 `print` 输出，Hook 返回 vfox 期望的表。

## 修改流程

1. 代码和测试一起修改。修复的问题要有一个没有该修复就会失败的测试。
2. 在 `docs/changes.md` 的 *Unreleased* 下添加条目，并在 `docs/zh-CN/changes.md` 中添加相同的条目。
3. 如果改动对用户可见，同时更新英文文档及其中文对应文件。
4. 运行上面的检查。

## 开发容器

`.devcontainer/` 会构建一个镜像，其中包含上面固定的工具：Go、StyLua、LuaLS、vfox、license-eye、actionlint 以及 Docker CLI。`devcontainer.json` 挂载了宿主机的 Docker 套接字，因此端到端测试会在宿主机的 Docker 守护进程上启动容器，与 CI 的方式相同。在开发容器中打开仓库后，如果创建后步骤没有完成，请运行 `cd tests/e2e && go mod download`。

## 发布

发布通过 [README](../../README_CN.md#发布本插件) 中的工作流完成。不要在拉取请求中手动修改 `PLUGIN.version`。发布之前，请通过拉取请求把[更新日志](changes.md)和[英文更新日志](../changes.md)中 *Unreleased* 下的条目移到新版本的标题下，这样发布时才会包含它们。
